import SwiftUI
import ExplorerCore
@preconcurrency import QuickLookThumbnailing

struct FileGridView: View {
    @ObservedObject var tab: BrowserTab
    var workspace: WorkspaceState
    @State private var collapsed: Set<String> = []
    @FocusState private var focused: Bool
    private var mode: ViewMode { tab.preferences.view }
    private var horizontal: Bool { mode == .tiles || mode == .content || mode == .smallIcons }
    private var iconSize: CGFloat {
        switch mode {
        case .smallIcons: return 24
        case .mediumIcons: return 48
        case .largeIcons: return 76
        case .extraLargeIcons: return 112
        case .tiles, .content: return 42
        default: return 48
        }
    }
    private var cellWidth: CGFloat {
        switch mode {
        case .smallIcons: return 190
        case .mediumIcons: return 116
        case .largeIcons: return 140
        case .extraLargeIcons: return 176
        case .tiles: return 270
        case .content: return 600
        default: return 140
        }
    }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(tab.groups) { group in
                    if !group.title.isEmpty {
                        Button {
                            if collapsed.contains(group.title) { collapsed.remove(group.title) } else { collapsed.insert(group.title) }
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: collapsed.contains(group.title) ? "chevron.right" : "chevron.down")
                                Text(group.title).fontWeight(.semibold)
                                Text("(\(group.entries.count))").foregroundStyle(.secondary)
                                Rectangle().fill(.quaternary).frame(height: 1)
                            }.font(.system(size: 12))
                        }.buttonStyle(.plain).padding(.top, 3)
                    }
                    if !collapsed.contains(group.title) {
                        LazyVGrid(columns: mode == .content ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: cellWidth), spacing: 8)], alignment: .leading, spacing: 8) {
                            ForEach(group.entries) { entry in cell(entry) }
                        }
                    }
                }
            }.padding(16)
        }
        .focusable().focused($focused).focusEffectDisabled()
        .onKeyPress(.return) { tab.openSelection(); return .handled }
        .onKeyPress(.space) { tab.showInspector.toggle(); return .handled }
        .onKeyPress(.leftArrow) { moveSelection(-1); return .handled }
        .onKeyPress(.rightArrow) { moveSelection(1); return .handled }
        .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
        .onKeyPress(.downArrow) { moveSelection(1); return .handled }
        .onDrop(of: [.fileURL], isTargeted: nil) { DropFiles.accept($0, folder: tab.location, tab: tab) }
        .contextMenu { FileContextMenu(tab: tab, openInTab: workspace.newTab) }
    }
    private func cell(_ entry: FileEntry) -> some View {
        Group {
            if horizontal {
                HStack(spacing: 10) {
                    FileThumbnail(url: entry.url, size: iconSize, preview: !entry.isDirectory && mode != .smallIcons)
                    labels(entry, centered: false)
                    Spacer(minLength: 0)
                    if mode == .content { Text(Display.date.string(from: entry.modified)).font(.caption).foregroundStyle(.secondary) }
                }.padding(9).frame(maxWidth: .infinity, minHeight: mode == .smallIcons ? 35 : 66, alignment: .leading)
            } else {
                VStack(spacing: 7) {
                    FileThumbnail(url: entry.url, size: iconSize, preview: !entry.isDirectory)
                    labels(entry, centered: true)
                }.padding(10).frame(maxWidth: .infinity).frame(height: iconSize + 70, alignment: .top)
            }
        }
        .background(tab.selection.contains(entry.url) ? Color.accentColor.opacity(0.16) : Color.clear, in: RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(tab.selection.contains(entry.url) ? Color.accentColor.opacity(0.6) : .clear, lineWidth: 1))
        .opacity(entry.isHidden ? 0.55 : 1)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { tab.open(entry) }
        .onTapGesture { focused = true; tab.select(entry) }
        .contextMenu {
            Button(L10n.text("action.open")) { tab.selection = [entry.url]; tab.open(entry) }
            if entry.navigable { Button(L10n.text("action.open_tab")) { workspace.newTab(entry.url) } }
            Divider()
            Button(L10n.text("selection.this")) { tab.selection = [entry.url] }
            Button(L10n.text("action.copy")) { selectForAction(entry); Operations.shared.copy(tab) }
            Button(L10n.text("action.cut")) { selectForAction(entry); Operations.shared.copy(tab, cut: true) }
            Button(L10n.text("action.rename_menu")) { tab.selection = [entry.url]; Operations.shared.rename(tab) }
            Button(L10n.text("action.copy_to")) { selectForAction(entry); Operations.shared.chooseDestination(tab, moving: false) }
            Button(L10n.text("action.move_to")) { selectForAction(entry); Operations.shared.chooseDestination(tab, moving: true) }
            Button(L10n.text("action.tags")) { selectForAction(entry); Operations.shared.editTags(tab) }
            Button(L10n.text("action.trash_menu")) { selectForAction(entry); Operations.shared.trash(tab) }
            Divider()
            Button(L10n.text("inspector.preview")) { tab.selection = [entry.url]; tab.showInspector = true }
            Button(L10n.text("action.finder")) { NSWorkspace.shared.activateFileViewerSelecting([entry.url]) }
        }
        .onDrag { NSItemProvider(object: entry.url as NSURL) }
        .onDrop(of: [.fileURL], isTargeted: nil) { entry.navigable ? DropFiles.accept($0, folder: entry.url, tab: tab) : false }
        .help(entry.url.path)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.name)
        .accessibilityAddTraits(tab.selection.contains(entry.url) ? .isSelected : [])
    }
    private func labels(_ entry: FileEntry, centered: Bool) -> some View {
        VStack(alignment: centered ? .center : .leading, spacing: 3) {
            Text(entry.displayName(showExtensions: tab.preferences.showExtensions)).font(.system(size: 12)).lineLimit(centered ? 2 : 1).multilineTextAlignment(centered ? .center : .leading)
            if mode == .tiles || mode == .content {
                Text(entry.kind + (entry.navigable ? "" : " · " + Display.size(entry))).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
            }
            if mode == .content { Text(entry.url.deletingLastPathComponent().path).font(.system(size: 10)).foregroundStyle(.tertiary).lineLimit(1) }
        }
    }
    private func selectForAction(_ entry: FileEntry) { if !tab.selection.contains(entry.url) { tab.selection = [entry.url] } }
    private func moveSelection(_ offset: Int) {
        let items = tab.visibleEntries
        guard !items.isEmpty else { return }
        let index = items.firstIndex { tab.selection.contains($0.url) } ?? (offset > 0 ? -1 : items.count)
        tab.selection = [items[max(0, min(items.count - 1, index + offset))].url]
    }
}

struct FileThumbnail: View {
    let url: URL
    let size: CGFloat
    var preview = true
    @State private var thumbnail: NSImage?
    var body: some View {
        Image(nsImage: thumbnail ?? IconCache.shared.icon(url))
            .resizable().scaledToFit().frame(width: size, height: size)
            .task(id: "\(url.path)-\(size)-\(preview)") {
                thumbnail = nil
                guard preview else { return }
                let request = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: size, height: size), scale: 2, representationTypes: .thumbnail)
                let result = await withTaskCancellationHandler(operation: {
                    await withCheckedContinuation { continuation in
                        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { image, _ in continuation.resume(returning: image?.nsImage) }
                    }
                }, onCancel: { QLThumbnailGenerator.shared.cancel(request) })
                if !Task.isCancelled { thumbnail = result }
            }
    }
}
