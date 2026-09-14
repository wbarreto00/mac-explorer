import Foundation

public enum Organization {
    public static func sorted(_ entries: [FileEntry], preferences p: FolderPreferences) -> [FileEntry] {
        entries.sorted { a, b in
            if p.foldersFirst && a.navigable != b.navigable { return a.navigable }
            var comparison: ComparisonResult
            switch p.sort {
            case .name: comparison = a.name.localizedStandardCompare(b.name)
            case .modified: comparison = a.modified.compare(b.modified)
            case .created: comparison = a.created.compare(b.created)
            case .added: comparison = a.added.compare(b.added)
            case .size: comparison = a.size == b.size ? .orderedSame : (a.size < b.size ? .orderedAscending : .orderedDescending)
            case .kind: comparison = a.kind.localizedStandardCompare(b.kind)
            case .fileExtension: comparison = a.fileExtension.localizedStandardCompare(b.fileExtension)
            case .tags: comparison = a.tags.joined().localizedStandardCompare(b.tags.joined())
            }
            if comparison == .orderedSame { comparison = a.name.localizedStandardCompare(b.name) }
            if comparison == .orderedSame { comparison = a.url.path.compare(b.url.path) }
            return p.ascending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    public static func groups(_ entries: [FileEntry], preferences p: FolderPreferences, now: Date = Date()) -> [FileGroup] {
        let ordered = sorted(entries, preferences: p)
        guard p.group != .none else { return [FileGroup(title: "", entries: ordered)] }
        var buckets: [String: [FileEntry]] = [:]
        var ranks: [String: Int] = [:]
        for item in ordered {
            let (label, rank) = groupKey(item, field: p.group, now: now)
            buckets[label, default: []].append(item)
            ranks[label] = rank
        }
        let titles = buckets.keys.sorted {
            let left = ranks[$0] ?? 0, right = ranks[$1] ?? 0
            let precedes = left == right ? $0.localizedStandardCompare($1) == .orderedAscending : left < right
            return p.groupsAscending ? precedes : !precedes
        }
        return titles.map { FileGroup(title: $0, entries: buckets[$0]!) }
    }

    private static func groupKey(_ item: FileEntry, field: GroupField, now: Date) -> (String, Int) {
        switch field {
        case .none: return ("", 0)
        case .name: return (String(item.name.prefix(1)).uppercased(), 0)
        case .kind: return (item.kind, 0)
        case .fileExtension: return (item.navigable ? L10n.text("files.folders") : (item.fileExtension.isEmpty ? L10n.text("extension.none") : "." + item.fileExtension), 0)
        case .tags: return (item.tags.isEmpty ? L10n.text("tags.none") : item.tags.joined(separator: ", "), 0)
        case .size:
            if item.navigable { return (L10n.text("files.folders"), -1) }
            switch item.size {
            case 0: return (L10n.text("group.size.empty"), 0)
            case 1..<16_384: return (L10n.text("group.size.tiny"), 1)
            case 16_384..<1_048_576: return (L10n.text("group.size.small"), 2)
            case 1_048_576..<134_217_728: return (L10n.text("group.size.medium"), 3)
            case 134_217_728..<1_073_741_824: return (L10n.text("group.size.large"), 4)
            default: return (L10n.text("group.size.huge"), 5)
            }
        case .modified, .created:
            let date = field == .modified ? item.modified : item.created
            let calendar = Calendar.current
            if date > now { return (L10n.text("group.future"), -1) }
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
            if days == 0 { return (L10n.text("group.today"), 0) }
            if days == 1 { return (L10n.text("group.yesterday"), 1) }
            if days < 7 { return (L10n.text("group.week"), 2) }
            if days < 30 { return (L10n.text("group.month"), 3) }
            if days < 365 { return (L10n.text("group.year"), 4) }
            return (L10n.text("group.older"), 5)
        }
    }
}
