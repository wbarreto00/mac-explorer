import Foundation
import UniformTypeIdentifiers

public struct FileEntry: Identifiable, Hashable, Sendable {
    public var id: URL { url }
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let isPackage: Bool
    public let isSymbolicLink: Bool
    public let size: Int64
    public let modified: Date
    public let created: Date
    public let added: Date
    public let kind: String
    public let tags: [String]
    public let isHidden: Bool
    public var navigable: Bool { isDirectory && !isPackage }
    public var fileExtension: String { url.pathExtension.lowercased() }

    public static let keys: Set<URLResourceKey> = [
        .isDirectoryKey, .isPackageKey, .isSymbolicLinkKey, .fileSizeKey,
        .contentModificationDateKey, .creationDateKey, .addedToDirectoryDateKey,
        .localizedTypeDescriptionKey, .isHiddenKey
    ]

    public init(url: URL, includeTags: Bool = false) throws {
        let keys = includeTags ? Self.keys.union([.tagNamesKey]) : Self.keys
        let values = try url.resourceValues(forKeys: keys)
        self.url = url.standardizedFileURL
        name = url.lastPathComponent
        isDirectory = values.isDirectory ?? false
        isPackage = values.isPackage ?? false
        isSymbolicLink = values.isSymbolicLink ?? false
        size = Int64(values.fileSize ?? 0)
        modified = values.contentModificationDate ?? .distantPast
        created = values.creationDate ?? .distantPast
        added = values.addedToDirectoryDate ?? created
        kind = isDirectory && !isPackage ? L10n.text("file.folder") : (values.localizedTypeDescription ?? UTType(filenameExtension: url.pathExtension)?.localizedDescription ?? L10n.text("file.generic"))
        tags = values.tagNames ?? []
        isHidden = values.isHidden ?? name.hasPrefix(".")
    }

    public func displayName(showExtensions: Bool) -> String {
        guard !showExtensions, !isDirectory, !fileExtension.isEmpty, !name.hasPrefix(".") else { return name }
        return url.deletingPathExtension().lastPathComponent
    }
}

public enum ViewMode: String, CaseIterable, Codable, Sendable {
    case details, list, smallIcons, mediumIcons, largeIcons, extraLargeIcons, tiles, content
    public var title: String {
        switch self {
        case .details: return L10n.text("view.details")
        case .list: return L10n.text("view.list")
        case .smallIcons: return L10n.text("view.icons.small")
        case .mediumIcons: return L10n.text("view.icons.medium")
        case .largeIcons: return L10n.text("view.icons.large")
        case .extraLargeIcons: return L10n.text("view.icons.extra")
        case .tiles: return L10n.text("view.tiles")
        case .content: return L10n.text("view.content")
        }
    }
    public var symbol: String {
        switch self {
        case .details: return "list.bullet.rectangle"
        case .list: return "list.bullet"
        case .smallIcons: return "square.grid.3x3"
        case .mediumIcons: return "square.grid.2x2"
        case .largeIcons, .extraLargeIcons: return "square.grid.2x2.fill"
        case .tiles: return "rectangle.grid.2x2"
        case .content: return "rectangle.grid.1x2"
        }
    }
}

public enum SortField: String, CaseIterable, Codable, Sendable {
    case name, modified, created, added, kind, size, fileExtension, tags
    public var title: String {
        switch self {
        case .name: return L10n.text("field.name")
        case .modified: return L10n.text("field.modified")
        case .created: return L10n.text("field.created")
        case .added: return L10n.text("field.added")
        case .kind: return L10n.text("field.kind")
        case .size: return L10n.text("field.size")
        case .fileExtension: return L10n.text("field.extension")
        case .tags: return L10n.text("field.tags")
        }
    }
}

public enum GroupField: String, CaseIterable, Codable, Sendable {
    case none, name, kind, modified, created, size, fileExtension, tags
    public var title: String {
        switch self {
        case .none: return L10n.text("group.none")
        case .name: return L10n.text("field.name")
        case .kind: return L10n.text("field.kind")
        case .modified: return L10n.text("field.modified")
        case .created: return L10n.text("field.created")
        case .size: return L10n.text("field.size")
        case .fileExtension: return L10n.text("field.extension")
        case .tags: return L10n.text("field.tags")
        }
    }
}

public struct FolderPreferences: Codable, Equatable, Sendable {
    public var view: ViewMode = .details
    public var sort: SortField = .name
    public var ascending = true
    public var group: GroupField = .none
    public var groupsAscending = true
    public var foldersFirst = true
    public var showHidden = false
    public var showExtensions = true
    public var columns: [SortField] = [.name, .modified, .kind, .size]
    public init() {}
}

public struct FileGroup: Identifiable, Sendable {
    public var id: String { title }
    public let title: String
    public let entries: [FileEntry]
}
