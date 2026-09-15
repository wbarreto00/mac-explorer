# Changelog

## 1.3.0 · 2026-09-15

- Right-click folders to add or remove Favorites in Details, List, icon views and the sidebar.
- Drag folders from the file area, sidebar or Finder onto the Favorites section to pin them. This saves references without copying or moving files.
- Favorites are saved across launches, normalized and deduplicated. Files and application bundles are ignored; disconnected saved folders are retained.
- Updated EN, PT-BR and ES menus and user guides. Added checks for favorites filtering, persistence, duplicate handling and non-destructive removal.

## 1.2.0 · 2026-09-14

First public GitHub release.

- English by default, with settings for English, Brazilian Portuguese, Spanish, or following macOS.
- README, installation instructions and user guide in all three languages.
- Optimized Apple Silicon app bundle, source package, MIT license and contribution guidance.
- 14 passing core checks, including language preference persistence and catalog parity.
- Folder tree, tabs, sorting, independent grouping, per-folder views, configurable columns, file operations, tags, preview and filename search.
- Background directory monitoring setup and deferred tag metadata avoid blocking ordinary folder browsing on slow metadata reads.

The app is signed locally, without Developer ID or notarization. Tested on macOS 26.6.2; the macOS 14 deployment target has not yet been verified across other supported OS versions.

## 1.1.0 · 2026-09-14

Local development build. Renamed the prototype to Mac Explorer, added complete EN/PT-BR/ES catalogs, localized native permission text, and retained existing preferences.

## 1.0.0 · 2026-09-14

Initial local prototype under the name Trilha, with Explorer-inspired folder organization and core file operations.
