import Foundation
import ExplorerCore

extension ExplorerCoreTests {
    func testFavoriteFolderFilteringAndDuplicates() throws {
        let first = try FileActions.newFolder(in: root, name: "First")
        let second = try FileActions.newFolder(in: root, name: "Second")
        let package = try FileActions.newFolder(in: root, name: "Example.app")
        let file = root.appendingPathComponent("document.txt")
        try "original".write(to: file, atomically: true, encoding: .utf8)
        let candidates = [first, first.appendingPathComponent("."), file, second, package, root.appendingPathComponent("missing"), URL(string: "https://example.com/folder")!]
        let accepted = FavoriteFolders.directories(in: candidates)
        XCTAssertEqual(accepted.map(\.lastPathComponent), ["First", "Second"])
        let added = FavoriteFolders.adding(accepted, to: [second])
        XCTAssertEqual(added.map(\.lastPathComponent), ["Second", "First"])
        XCTAssertEqual(FavoriteFolders.adding(accepted, to: added), added)
        XCTAssertEqual(FavoriteFolders.removing([first.appendingPathComponent(".")], from: added), [second.standardizedFileURL])
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.path))
        XCTAssertEqual(try String(contentsOf: file), "original")
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path).count, 4)
    }

    func testFavoritesPersistenceAndEmptyList() throws {
        let domain = "MacExplorerFavoritesChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let folder = try FileActions.newFolder(in: root, name: "Saved")
        let offline = root.appendingPathComponent("Disconnected")
        XCTAssertEqual(FavoriteFolders.load(from: defaults, fallback: [folder]), [folder.standardizedFileURL])
        FavoriteFolders.save([folder, folder, offline], to: defaults)
        let reopened = UserDefaults(suiteName: domain)!
        XCTAssertEqual(FavoriteFolders.load(from: reopened, fallback: []), FavoriteFolders.normalized([folder, offline]))
        FavoriteFolders.save([], to: defaults)
        XCTAssertEqual(FavoriteFolders.load(from: reopened, fallback: [folder]), [])
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.path))
    }
}
