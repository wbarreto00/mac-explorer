import SwiftUI
import ExplorerCore
import QuickLookUI

struct InspectorView: View {
    @ObservedObject var tab: BrowserTab
    @State private var tags: [String]?
    @State private var tagReadFailed = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(L10n.text("inspector.title")).font(.headline)
                    Spacer()
                    Button { tab.showInspector = false } label: { Image(systemName: "xmark") }.buttonStyle(.plain).foregroundStyle(.secondary)
                }
                if tab.selectedEntries.count == 1, let item = tab.selectedEntries.first {
                    VStack(spacing: 12) {
                        if item.navigable {
                            FileThumbnail(url: item.url, size: 90, preview: false).padding(.vertical, 20)
                        } else { QuickLookPreview(url: item.url).frame(height: 210).id(item.url) }
                        Text(item.name).font(.title3.weight(.semibold)).multilineTextAlignment(.center).textSelection(.enabled)
                        Text(item.kind).font(.callout).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity)
                    Divider()
                    property(L10n.text("field.location"), item.url.deletingLastPathComponent().path)
                    if !item.navigable { property(L10n.text("field.size"), Display.size(item) + " (\(item.size) bytes)") }
                    property(L10n.text("date.modified"), Display.date.string(from: item.modified))
                    property(L10n.text("date.created"), Display.date.string(from: item.created))
                    property(L10n.text("date.added"), Display.date.string(from: item.added))
                    if item.isSymbolicLink { property(L10n.text("file.symlink"), item.url.resolvingSymlinksInPath().path) }
                    property(L10n.text("field.tags"), tags.map { $0.isEmpty ? L10n.text("tags.none") : $0.joined(separator: ", ") } ?? L10n.text(tagReadFailed ? "tags.read_error" : "tags.loading"))
                    HStack {
                        Button(L10n.text("action.open")) { tab.open(item) }
                        Button(L10n.text("action.tags")) { Operations.shared.editTags(tab) }
                    }
                    Button(L10n.text("action.finder")) { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }
                } else if tab.selectedEntries.count > 1 {
                    Image(systemName: "doc.on.doc").font(.system(size: 45, weight: .ultraLight)).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 25)
                    Text(L10n.count("count.selected_items", tab.selection.count)).font(.title3)
                    property(L10n.text("files"), "\(tab.selectedEntries.filter { !$0.navigable }.count)")
                    property(L10n.text("files.folders"), "\(tab.selectedEntries.filter(\.navigable).count)")
                    property(L10n.text("selection.size"), ByteCountFormatter.string(fromByteCount: tab.selectedEntries.filter { !$0.navigable }.reduce(0) { $0 + $1.size }, countStyle: .file))
                    Text(L10n.text("size.excludes_folders")).font(.caption).foregroundStyle(.secondary)
                } else {
                    Image(systemName: "cursorarrow.click").font(.system(size: 38, weight: .ultraLight)).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.top, 50)
                    Text(L10n.text("inspector.empty")).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
            }.padding(18)
        }.background(.regularMaterial)
        .task(id: "\(tab.selectedEntries.first?.url.path ?? "")|\(tab.isLoading)") {
            tags = nil; tagReadFailed = false
            guard !tab.isLoading, tab.selectedEntries.count == 1, let item = tab.selectedEntries.first else { return }
            let result = await Task.detached(priority: .utility) {
                try? (item.url.resourceValues(forKeys: [.tagNamesKey]).tagNames ?? [])
            }.value
            guard !Task.isCancelled else { return }
            if let result { tags = result } else { tagReadFailed = true }
        }
    }
    private func property(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 12)).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct QuickLookPreview: NSViewRepresentable {
    let url: URL
    func makeNSView(context: Context) -> QLPreviewView { QLPreviewView(frame: .zero, style: .compact)! }
    func updateNSView(_ view: QLPreviewView, context: Context) { view.previewItem = url as NSURL; view.autostarts = false }
    static func dismantleNSView(_ view: QLPreviewView, coordinator: ()) { view.close() }
}
