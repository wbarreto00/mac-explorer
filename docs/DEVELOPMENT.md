# Development and releases

## Toolchain

Mac Explorer is a SwiftPM executable package targeting Apple Silicon and macOS 14+. It declares Swift tools 5.9. The verified development environment is Swift 6.4, Command Line Tools, macOS 26.6.2, and the macOS 26 SDK. Earlier supported deployment versions need testing on actual machines; the deployment target alone is not a compatibility certification.

The scripts choose the locally available SDK matching the host macOS major version when present, otherwise `xcrun --show-sdk-path`. They do not change the system's selected Xcode. They currently request SwiftPM's native build system to avoid a missing SwiftUIMacros plugin in the developer machine's default macOS 27 SDK. This flag is deprecated in Swift 6.4 and may need adaptation with future toolchains. If an SDK/plugin error appears, verify `xcode-select -p`, `xcrun --show-sdk-path` and `swift --version`, and select a complete Apple toolchain.

## Structure

| Path | Responsibility |
|---|---|
| `Sources/ExplorerCore` | Metadata, organization, filename search, filesystem operations and localization |
| `Sources/MacExplorer/App` | Entry point, native language setup and menu commands |
| `Sources/MacExplorer/Stores` | Tabs, navigation and folder preferences |
| `Sources/MacExplorer/Services` | Operations, clipboard, drops and directory monitoring |
| `Sources/MacExplorer/Views` | SwiftUI composition with AppKit tree/table and Quick Look |
| `Resources` | App Info.plist, icon and translated permission descriptions |
| `Tests/ExplorerCoreTests` | Standalone assertion runner and temporary filesystem fixtures |
| `script` | Build, package, icon generation and validation |

## Run and check

```sh
./script/test.sh
./script/build_and_run.sh --build-only
./script/build_and_run.sh --verify
```

The build defaults to an optimized `release` configuration. Use `CONFIGURATION=debug` for debugging. The runner covers natural sorting, grouping, collision preservation, move/restore conflicts, recursive and symlink guards, invalid names, hidden/recursive search, dangling links, preferences, deferred tags, English default and saved language settings, system language resolution, catalog parity and pluralization. It uses temporary files and an isolated defaults suite; it does not need XCTest. A full UI test suite is not included.

For release validation, also open the packaged app and verify a folder list, navigation, language changes, and a copy/move operation on disposable fixtures. Test EN, PT-BR, ES and Follow macOS language. Do not use personal documents as test fixtures. A language change takes effect after quitting and reopening.

## Localization

Use semantic `L10n.text`, `L10n.format` and `L10n.count` keys for app-authored strings. Keep all three `Localizable.strings` catalogs aligned and preserve format placeholders. Native controls use the app's own `AppleLanguages` preference, configured before SwiftUI starts. English is the default; selecting `system` removes this app-specific override. No global macOS preferences are changed. Regional date/size formats remain separate.

The SwiftPM resource bundle must be copied into the app's Resources folder. Command-line checks load it alongside their executable, so neither path depends on the developer's checkout. The accessor supports SwiftPM's lowercase `pt-br.lproj` normalization. Release builds remap source paths and strip debug symbols before signing. The internal bundle ID `io.wellington.trilha` is retained from the prototype to keep favorites and saved layouts. Do not change it casually.

## Package and publish

1. Update `CFBundleShortVersionString`, `CFBundleVersion`, and `CHANGELOG.md`.
2. Run core checks and `./script/build_and_run.sh --build-only`.
3. Extract the resulting ZIP into a temporary directory; run `codesign --verify --deep --strict` against that extracted app, then inspect `file` for its main executable and `plutil -lint` for Info.plist. Launch it through `open`, not the raw executable.
4. Confirm language resources work independently of the source tree and review the public files for local paths or credentials.
5. Compute the published ZIP checksum from inside `outputs/`: `shasum -a 256 Mac-Explorer-Apple-Silicon.zip > SHA256SUMS.txt`.
6. Tag the exact tested commit and create a GitHub release with the app ZIP, checksum file and release notes. GitHub supplies source archives for the tag.
7. Download the public assets and verify them again. Never claim notarization based on ad hoc signature validation.

Packaging happens in a temporary directory to avoid extended attributes introduced by synced source directories. The app has no embedded frameworks or helpers. The build currently signs with an ad hoc identity, suitable for local builds but not Apple Developer ID distribution. For a future notarized release, obtain an authorized Developer ID certificate, sign with hardened runtime and a secure timestamp, submit with Apple's `notarytool`, wait for acceptance, staple and validate the result. Never commit certificates or credentials. See [Apple's notarization documentation](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Privacy and filesystem boundaries

The app has no app-owned network client, telemetry, updater or account system. File access relies on macOS permissions and mounted filesystems. Copy/move conflicts must preserve both files, rename must refuse occupied paths, and restore must never overwrite. Keep potentially blocking filesystem reads off the UI thread. Changes to these rules need regression checks and explicit release notes.

`AppSettingsView` hosts Language and Permissions tabs. `PermissionsSettingsView` opens the macOS-owned Full Disk Access pane through `NSWorkspace` and can reveal `Bundle.main.bundleURL` in Finder. The pane shortcut is best effort, with a manual navigation path on failure. It never grants permission, reads or edits the TCC database, or stores a local flag claiming access is enabled. Test the destination from a different System Settings pane and verify that Finder selects the running bundle.

Ad hoc signatures have a code-hash-based identity. Rebuilding or updating can invalidate prior privacy grants; Full Disk Access is not a substitute for a stable signing identity. See [Apple's explanation of TCC and signing](https://developer.apple.com/forums/thread/663889). Avoid rebuilding the user's copy when only diagnosing whether an existing grant persists across launches.
