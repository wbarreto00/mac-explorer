# Mac Explorer

**A native file manager for Apple Silicon, with Windows Explorer-style folder organization.**

English · [Português (Brasil)](docs/README.pt-BR.md) · [Español](docs/README.es.md)

Browse a folder tree, work in tabs, sort and group files independently, and keep a different layout for each folder. Built with SwiftUI and AppKit, with no external package dependencies, accounts, ads, or analytics.

**[Download Mac Explorer](https://github.com/wbarreto00/mac-explorer/releases/latest)** · [User guide](docs/USER_GUIDE.md) · [Report a bug](https://github.com/wbarreto00/mac-explorer/issues/new?template=bug_report.md)

## Install

1. Use a Mac with **Apple Silicon (M1 or later)**. Intel Macs and Rosetta are not supported. The deployment target is **macOS 14 or later**; this release has been tested on macOS 26.6.2 only.
2. Open the [latest release](https://github.com/wbarreto00/mac-explorer/releases/latest) and download **Mac-Explorer-Apple-Silicon.zip**. GitHub's “Source code” archives are for developers, not the ready-to-run app.
3. Double-click the ZIP, then drag **Mac Explorer.app** to **Applications**.
4. Open Mac Explorer. Allow access to the folders you want to browse when macOS asks.

**Signing status:** this release is signed locally (ad hoc), without Apple Developer ID or notarization. macOS may block a downloaded copy. If you trust this release, try opening it once, then use **System Settings → Privacy & Security → Open Anyway**, as described in [Apple's guide](https://support.apple.com/guide/mac-help/mh40616/mac). You can also [build from source](#build-from-source). This is an early public release; other Mac and macOS combinations have not yet been verified.

For an optional integrity check, download `SHA256SUMS.txt` into the same folder as the ZIP and run:

```sh
shasum -a 256 -c SHA256SUMS.txt
```

To update, quit the app and replace the old copy in Applications. Favorites and folder layouts are preserved. To uninstall, move the app to Trash; it does not install a service or login item.

## Language

**English is the default.** Open **Mac Explorer → Settings…** (⌘,) and select:

- English
- Português (Brasil)
- Español
- Follow macOS language

Quit and reopen the app after changing the language. “Follow macOS language” picks a supported language from your macOS preferences, falling back to English. Portuguese variants use Brazilian Portuguese. File names are never translated, and dates and sizes retain your Mac's regional formats.

## Features

| Area | Available |
|---|---|
| Navigation | Expandable folder tree, favorites, tabs, windows, back/forward/up, clickable and editable paths |
| Views | Details, list, four icon sizes, tiles, content, native preview and properties |
| Sorting | Name, kind, size, extension, tags, modified/created/added dates; ascending or descending; folders first |
| Grouping | Name, kind, size, extension, tags, modified or created date, independent from sort order |
| Details | Choose, resize and reorder columns; save layouts per folder or as the default |
| Files | New folder, rename, copy/cut/paste, copy/move to, edit tags, Trash, limited move undo |
| Search | File-name search in the current folder or subfolders, with a 10,000-result limit |
| Volumes | Local disks, removable drives, and network shares already mounted in macOS |

### File behavior

- Drag and drop **copies**. Use Cut/Paste or Move To to move.
- Copy/move name conflicts preserve both items with a numbered suffix. There is no automatic overwrite or folder merging.
- Undo Last Move restores the last move, rename, or Trash operation during the current session. It refuses to overwrite an occupied original path.
- Copies, new folders, and tag edits have no undo. Search matches names, not document contents.
- Tags load when requested by a view, sort, group, preview, or edit, so ordinary browsing does not wait on tag metadata.

See the [user guide](docs/USER_GUIDE.md) for keyboard shortcuts, grouping and limitations.

## Build from source

Use Apple Silicon, macOS 14+, and Apple's **Xcode or Command Line Tools** with Swift 5.9 or later. The verified toolchain is Swift 6.4 with the macOS 26 SDK. Install missing developer tools with `xcode-select --install` and complete Apple's installer.

```sh
git clone https://github.com/wbarreto00/mac-explorer.git
cd mac-explorer
./script/test.sh
./script/build_and_run.sh
```

The build script produces an optimized arm64 app and ZIP in `outputs/`, signs the bundle locally, and opens it. To package without launching, use `./script/build_and_run.sh --build-only`. To build a debug version, use `CONFIGURATION=debug ./script/build_and_run.sh`.

There are no third-party Swift packages to download. The core test runner works without XCTest or full Xcode. [Development notes](docs/DEVELOPMENT.md) explain SDK selection, project structure, tests, and public releases.

## Privacy and limitations

Mac Explorer works with local files and mounted volumes through macOS APIs. It has no app-owned telemetry, sign-in, updater, or remote service. Preferences are saved locally. Opening files uses their associated applications; cloud-backed folders and network shares still use their respective providers.

This app does not replace Finder or reproduce every Windows Explorer feature. There is no dual pane, archive extraction, bulk rename, direct SMB connection dialog, or full operation history. Refresh a recursive search with ⌘R after subfolder changes. Large or unavailable volumes and third-party preview providers may take time to respond.

## Contribute

Issues and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), and the [changelog](CHANGELOG.md).

Released under the [MIT license](LICENSE). Independent project by [wbarreto00](https://github.com/wbarreto00); not affiliated with Apple or Microsoft.
