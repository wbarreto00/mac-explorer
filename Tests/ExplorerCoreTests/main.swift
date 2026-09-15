import Foundation

// A tiny assertion runner keeps the actual filesystem checks runnable with
// Apple's Command Line Tools, which do not bundle the XCTest framework.
var failures: [String] = []
func XCTAssertEqual<T: Equatable>(_ actual: @autoclosure () throws -> T, _ expected: @autoclosure () throws -> T, file: StaticString = #filePath, line: UInt = #line) {
    do { if try actual() != expected() { failures.append("Equality failed: \(file):\(line)") } }
    catch { failures.append("Unexpected error at \(line): \(error)") }
}
func XCTAssertTrue(_ value: @autoclosure () throws -> Bool, line: UInt = #line) {
    do { if try !value() { failures.append("Expected true at line \(line)") } } catch { failures.append("Unexpected error: \(error)") }
}
func XCTAssertFalse(_ value: @autoclosure () throws -> Bool, line: UInt = #line) {
    do { if try value() { failures.append("Expected false at line \(line)") } } catch { failures.append("Unexpected error: \(error)") }
}
func XCTAssertThrowsError<T>(_ value: @autoclosure () throws -> T, line: UInt = #line) {
    do { _ = try value(); failures.append("Expected an error at line \(line)") } catch { }
}

let suite = ExplorerCoreTests()
let checks: [(String, () throws -> Void)] = [
    ("Natural sort and folders first", suite.testNaturalSortAndFoldersFirstInBothDirections),
    ("Independent group order", suite.testGroupsRespectSortInsideGroups),
    ("Collision preserves both files", suite.testCopyCollisionPreservesBothContents),
    ("Move and undo conflicts", suite.testMoveAndUndoWithoutOverwriting),
    ("Recursive and symlink destinations", suite.testRecursiveDestinationIncludingSymlinkIsRejected),
    ("Invalid names and rename conflicts", suite.testInvalidNamesAndRenameCollision),
    ("Hidden files and recursive search", suite.testHiddenFilesAndRecursiveSearch),
    ("Dangling symlink collision", suite.testDanglingLinkCountsAsCollision),
    ("Preferences persistence", suite.testPreferencesRoundTrip),
    ("Deferred tag metadata", suite.testTagsAreReadOnlyWhenRequested),
    ("Favorite folders reject files and deduplicate without moving", suite.testFavoriteFolderFilteringAndDuplicates),
    ("Favorites persist, including empty and disconnected lists", suite.testFavoritesPersistenceAndEmptyList),
    ("English default and saved language choice", suite.testDefaultAndSelectedLanguage),
    ("System language matching and fallback", suite.testLanguageResolution),
    ("Complete EN, PT-BR and ES catalogs", suite.testCompleteCatalogsAndFormatting),
    ("Localized singular and plural counts", suite.testLocalizedCounts)
]
for (name, check) in checks {
    let before = failures.count
    do { try suite.setUpWithError(); try check() } catch { failures.append("\(name): \(error)") }
    do { try suite.tearDownWithError() } catch { failures.append("Cleanup: \(error)") }
    print("\(before == failures.count ? "PASS" : "FAIL") \(name)")
}
failures.forEach { print($0) }
print("\(checks.count) checks, \(failures.count) failures")
exit(failures.isEmpty ? 0 : 1)
