import Foundation
import ExplorerCore

final class ExplorerCoreTests {
    var root: URL!
    func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("TrilhaTests-" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    }
    func tearDownWithError() throws { if let root { try FileManager.default.removeItem(at: root) } }
    @discardableResult private func file(_ name: String, text: String = "conteúdo", folder: URL? = nil) throws -> URL {
        let url = (folder ?? root).appendingPathComponent(name)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    func testNaturalSortAndFoldersFirstInBothDirections() throws {
        try file("arquivo10.txt"); try file("arquivo2.txt")
        _ = try FileActions.newFolder(in: root, name: "Z pasta")
        let items = try FileService.list(root, showHidden: false).entries
        var settings = FolderPreferences()
        XCTAssertEqual(Organization.sorted(items, preferences: settings).map(\.name), ["Z pasta", "arquivo2.txt", "arquivo10.txt"])
        settings.ascending = false
        XCTAssertEqual(Organization.sorted(items, preferences: settings).map(\.name), ["Z pasta", "arquivo10.txt", "arquivo2.txt"])
    }
    func testGroupsRespectSortInsideGroups() throws {
        try file("10.txt"); try file("2.txt"); try file("1.csv")
        var settings = FolderPreferences(); settings.group = .fileExtension; settings.ascending = false
        let groups = Organization.groups(try FileService.list(root, showHidden: false).entries, preferences: settings)
        XCTAssertEqual(groups.map(\.title), [".csv", ".txt"])
        XCTAssertEqual(groups[1].entries.map(\.name), ["10.txt", "2.txt"])
        settings.groupsAscending = false
        XCTAssertEqual(Organization.groups(try FileService.list(root, showHidden: false).entries, preferences: settings).map(\.title), [".txt", ".csv"])
    }
    func testCopyCollisionPreservesBothContents() throws {
        let source = try file("relatório.txt", text: "novo")
        let destination = try FileActions.newFolder(in: root, name: "destino")
        let existing = try file("relatório.txt", text: "original", folder: destination)
        let target = try FileActions.transfer(source: source, folder: destination, moving: false)
        XCTAssertEqual(target.lastPathComponent, "relatório (2).txt")
        XCTAssertEqual(try String(contentsOf: existing), "original")
        XCTAssertEqual(try String(contentsOf: target), "novo")
        XCTAssertTrue(FileActions.exists(source))
        XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: destination.path).contains { $0.hasPrefix(".trilha-copy-") })
    }
    func testMoveAndUndoWithoutOverwriting() throws {
        let source = try file("mover.txt")
        let destination = try FileActions.newFolder(in: root, name: "destino")
        let target = try FileActions.transfer(source: source, folder: destination, moving: true)
        XCTAssertFalse(FileActions.exists(source))
        let move = CompletedMove(original: source, current: target)
        try file("mover.txt", text: "ocupado")
        XCTAssertThrowsError(try FileActions.restore(move))
        XCTAssertTrue(FileActions.exists(target))
        try FileManager.default.removeItem(at: source)
        try FileActions.restore(move)
        XCTAssertTrue(FileActions.exists(source)); XCTAssertFalse(FileActions.exists(target))
    }
    func testRecursiveDestinationIncludingSymlinkIsRejected() throws {
        let source = try FileActions.newFolder(in: root, name: "origem")
        let child = try FileActions.newFolder(in: source, name: "filha")
        XCTAssertThrowsError(try FileActions.transfer(source: source, folder: child, moving: false))
        let link = root.appendingPathComponent("atalho")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: child)
        XCTAssertThrowsError(try FileActions.transfer(source: source, folder: link, moving: true))
    }
    func testInvalidNamesAndRenameCollision() throws {
        for name in ["", " ", ".", "..", "a/b", "a:b", "a\u{0000}b"] { XCTAssertThrowsError(try FileActions.validateName(name)) }
        let source = try file("A.txt"), occupied = try file("B.txt")
        XCTAssertThrowsError(try FileActions.rename(source, to: "B.txt"))
        XCTAssertTrue(FileActions.exists(source)); XCTAssertTrue(FileActions.exists(occupied))
    }
    func testHiddenFilesAndRecursiveSearch() throws {
        try file(".segredo.txt")
        let child = try FileActions.newFolder(in: root, name: "subpasta")
        try file("relatório.txt", folder: child)
        XCTAssertEqual(try FileService.list(root, showHidden: false).entries.count, 1)
        XCTAssertEqual(try FileService.list(root, showHidden: true).entries.count, 2)
        XCTAssertEqual(try FileService.search(root, query: "RELATORIO", showHidden: false, cancelled: { false }).entries.map(\.name), ["relatório.txt"])
        XCTAssertThrowsError(try FileService.search(root, query: "a", showHidden: false, cancelled: { true }))
    }
    func testDanglingLinkCountsAsCollision() throws {
        let link = root.appendingPathComponent("link.txt")
        try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: "/nonexistent-trilha-test")
        XCTAssertTrue(FileActions.exists(link))
        XCTAssertEqual(FileActions.availableURL(in: root, name: "link.txt").lastPathComponent, "link (2).txt")
    }
    func testPreferencesRoundTrip() throws {
        var settings = FolderPreferences(); settings.group = .size; settings.view = .extraLargeIcons
        settings.columns = [.name, .tags, .created]; settings.showHidden = true
        XCTAssertEqual(try JSONDecoder().decode(FolderPreferences.self, from: JSONEncoder().encode(settings)), settings)
    }
    func testTagsAreReadOnlyWhenRequested() throws {
        let source = try file("tagged.txt")
        try (source as NSURL).setResourceValue(["QA"], forKey: .tagNamesKey)
        let basic = try FileService.list(root, showHidden: false).entries
        XCTAssertEqual(basic.first?.tags, [])
        let detailed = try FileService.list(root, showHidden: false, includeTags: true).entries
        XCTAssertEqual(detailed.first?.tags, ["QA"])
        let search = try FileService.search(root, query: "tagged", showHidden: false, includeTags: true, cancelled: { false })
        XCTAssertEqual(search.entries.first?.tags, ["QA"])
    }
}
