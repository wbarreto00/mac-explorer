import Foundation

public struct DirectoryResult: Sendable {
    public let entries: [FileEntry]
    public let skipped: Int
    public let limited: Bool
}

public enum FileService {
    public static func list(_ folder: URL, showHidden: Bool, includeTags: Bool = false) throws -> DirectoryResult {
        let keys = includeTags ? FileEntry.keys.union([.tagNamesKey]) : FileEntry.keys
        let urls = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: Array(keys), options: showHidden ? [] : [.skipsHiddenFiles])
        var skipped = 0
        let entries = urls.compactMap { url -> FileEntry? in
            do { return try FileEntry(url: url, includeTags: includeTags) } catch { skipped += 1; return nil }
        }
        return DirectoryResult(entries: entries, skipped: skipped, limited: false)
    }

    public static func search(_ folder: URL, query: String, showHidden: Bool, includeTags: Bool = false, cancelled: () -> Bool) throws -> DirectoryResult {
        // Validate access first so an unreadable root never looks like an empty search.
        _ = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        var skipped = 0
        var options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants]
        if !showHidden { options.insert(.skipsHiddenFiles) }
        let keys = includeTags ? FileEntry.keys.union([.tagNamesKey]) : FileEntry.keys
        guard let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: Array(keys), options: options, errorHandler: { _, _ in skipped += 1; return true }) else {
            throw CocoaError(.fileReadNoPermission)
        }
        var entries: [FileEntry] = []
        let limit = 10_000
        for case let url as URL in enumerator {
            if cancelled() { throw CancellationError() }
            if url.lastPathComponent.localizedStandardContains(query) {
                if let entry = try? FileEntry(url: url, includeTags: includeTags) { entries.append(entry) } else { skipped += 1 }
                if entries.count >= limit { return DirectoryResult(entries: entries, skipped: skipped, limited: true) }
            }
        }
        return DirectoryResult(entries: entries, skipped: skipped, limited: false)
    }
}

public enum FileActionError: LocalizedError {
    case invalidName, missingSource, invalidDestination, recursiveDestination, sameLocation, collision, changedSinceOperation
    public var errorDescription: String? {
        switch self {
        case .invalidName: return L10n.text("error.invalid_name")
        case .missingSource: return L10n.text("error.missing_source")
        case .invalidDestination: return L10n.text("error.destination")
        case .recursiveDestination: return L10n.text("error.recursive")
        case .sameLocation: return L10n.text("error.same_location")
        case .collision: return L10n.text("error.collision")
        case .changedSinceOperation: return L10n.text("error.changed")
        }
    }
}

public struct CompletedMove: Sendable {
    public let original: URL
    public let current: URL
    public init(original: URL, current: URL) { self.original = original; self.current = current }
}

public enum FileActions {
    public static func validateName(_ name: String) throws {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || name == "." || name == ".." || name.contains("/") || name.contains(":") || name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) {
            throw FileActionError.invalidName
        }
    }

    public static func exists(_ url: URL) -> Bool {
        // attributesOfItem also detects dangling symbolic links.
        (try? FileManager.default.attributesOfItem(atPath: url.path)) != nil
    }

    public static func availableURL(in folder: URL, name: String) -> URL {
        var candidate = folder.appendingPathComponent(name)
        let original = URL(fileURLWithPath: name)
        let ext = original.pathExtension
        let stem = ext.isEmpty ? name : original.deletingPathExtension().lastPathComponent
        var n = 2
        while exists(candidate) {
            candidate = folder.appendingPathComponent("\(stem) (\(n))" + (ext.isEmpty ? "" : ".\(ext)"))
            n += 1
        }
        return candidate
    }

    public static func validateTransfer(source: URL, folder: URL, moving: Bool) throws {
        guard exists(source) else { throw FileActionError.missingSource }
        let values = try folder.resourceValues(forKeys: [.isDirectoryKey])
        guard values.isDirectory == true else { throw FileActionError.invalidDestination }
        let resolvedSource = source.resolvingSymlinksInPath().standardizedFileURL
        let resolvedFolder = folder.resolvingSymlinksInPath().standardizedFileURL
        if moving && source.deletingLastPathComponent().resolvingSymlinksInPath().standardizedFileURL == resolvedFolder { throw FileActionError.sameLocation }
        let sourceValues = try source.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        if sourceValues.isDirectory == true && sourceValues.isSymbolicLink != true && (resolvedSource.path == "/" || resolvedFolder == resolvedSource || resolvedFolder.path.hasPrefix(resolvedSource.path + "/")) {
            throw FileActionError.recursiveDestination
        }
    }

    public static func transfer(source: URL, folder: URL, moving: Bool) throws -> URL {
        try validateTransfer(source: source, folder: folder, moving: moving)
        if moving {
            let target = availableURL(in: folder, name: source.lastPathComponent)
            try FileManager.default.moveItem(at: source, to: target)
            return target
        }
        // Publish a copy only after it is complete. Failed copies are confined
        // to a staging directory created exclusively for this operation.
        let staging = folder.appendingPathComponent(".trilha-copy-" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: staging) }
        let payload = staging.appendingPathComponent(source.lastPathComponent)
        try FileManager.default.copyItem(at: source, to: payload)
        let target = availableURL(in: folder, name: source.lastPathComponent)
        try FileManager.default.moveItem(at: payload, to: target)
        return target
    }

    public static func rename(_ source: URL, to name: String) throws -> CompletedMove {
        try validateName(name)
        let target = source.deletingLastPathComponent().appendingPathComponent(name)
        if source.standardizedFileURL == target.standardizedFileURL { return CompletedMove(original: source, current: source) }
        guard !exists(target) else { throw FileActionError.collision }
        try FileManager.default.moveItem(at: source, to: target)
        return CompletedMove(original: source, current: target)
    }

    public static func newFolder(in parent: URL, name: String) throws -> URL {
        try validateName(name)
        let target = parent.appendingPathComponent(name, isDirectory: true)
        guard !exists(target) else { throw FileActionError.collision }
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
        return target
    }

    public static func trash(_ source: URL) throws -> CompletedMove {
        var result: NSURL?
        try FileManager.default.trashItem(at: source, resultingItemURL: &result)
        guard let target = result as URL? else { throw FileActionError.missingSource }
        return CompletedMove(original: source, current: target)
    }

    public static func restore(_ move: CompletedMove) throws {
        guard !exists(move.original) else { throw FileActionError.collision }
        try FileManager.default.moveItem(at: move.current, to: move.original)
    }
}
