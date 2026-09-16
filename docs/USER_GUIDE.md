# User guide

English · [Português (Brasil)](USER_GUIDE.pt-BR.md) · [Español](USER_GUIDE.es.md) · [Install](../README.md#install)

## Browse and organize

Expand the arrows in the left sidebar to browse folders. Click a folder to display its contents. Double-click a folder in the file area to enter it, or a file to open its associated app. Use the path bar to jump to a parent; ⌘L accepts an absolute path or a path beginning with `~`.

Right-click a folder and choose **Add to Favorites**, or drag folders from the file area, sidebar or Finder onto **Favorites** in the left sidebar. You can also drop onto a row within the Favorites section. These actions save shortcuts to the original locations without copying or moving folders. Repeated additions do not create duplicates, and your list is saved when you quit. Right-click a saved folder and choose **Remove from Favorites** to remove only the shortcut. The star beside Navigation still adds or removes the current folder.

Connected drives and network shares appear after macOS mounts them. Saved favorites on disconnected drives remain in your list. This app does not connect to an unmounted network server itself.

In **Organize**, choose **Sort by** and **Group by** separately. For example, group by Kind, then sort by Modified to see recently changed files within each type. Ascending/descending group order is independent of sorting inside each group. Folders First is optional. In Details, double-click a group header to collapse it; in icon views, click the header.

**View** changes the presentation and visible columns. Resize a column by dragging its boundary and reorder it by dragging its heading. Each folder remembers its layout. **Use This Layout as Default** applies it to folders without their own saved layout. Use Show Hidden Files and Show Extensions when needed.

## Select, search, and preview

Use ⌘-click for separate items, Shift-click for a range, or ⌘A for all visible items. Search filters names in the current folder; enable the subfolder option for a recursive search. Results stop at 10,000, and unreadable items or limits are reported in the status area. Refresh recursive results with ⌘R after changes in subfolders.

The properties panel shows the selection, dates, tags and Quick Look previews. Preview support depends on macOS and installed preview providers. Folder sizes are not recursively calculated. Tag reads may wait for a filesystem provider, but ordinary folder lists do not request them unless needed.

## File operations

The toolbar, menus and context menus offer New Folder, Rename, Copy, Cut, Paste, Copy To, Move To, Tags and Move to Trash. Drag and drop copies. Tags are comma-separated; applying an empty value removes them. For multiple files, the entered tags replace the tags of every selected item.

Copy and move operations preserve name conflicts by adding a number. Renaming to an existing name is refused. Folders are not automatically merged. Trash uses the macOS Trash rather than permanent deletion.

**Undo Last Move** restores the last move, rename or Trash operation while the app remains open, and refuses to overwrite an existing original path. It is a single operation record, not a complete undo history. Copy, folder creation and tags are not covered. Keep backups of important files as you normally would.

## Keyboard shortcuts

| Action | Shortcut |
|---|---|
| New window / new tab | ⌘N / ⌘T |
| Close tab / next tab | ⌘⇧W / Control+Tab |
| New folder / search | ⌘⇧N / ⌘F |
| Go to folder | ⌘L |
| Back / forward / parent | ⌘← / ⌘→ / ⌘↑ |
| Open selection | ⌘↓ or Enter |
| Copy / cut / paste | ⌘C / ⌘X / ⌘V |
| Select all | ⌘A |
| Rename in Details/List | F2 (or fn+F2) |
| Properties and preview | Space or ⌘⌥I |
| Refresh / hidden files | ⌘R / ⌘⇧. |
| Move to Trash | ⌘⌫ |
| Undo Last Move | ⌘⌥Z |
| Language and permissions settings | ⌘, |

## File access permissions

Open **Mac Explorer → Settings… → Permissions** (⌘,) and click **Open Full Disk Access…**. This optional setting gives Mac Explorer broad access to protected files, including other apps' data and backups. Individual folder permissions remain available if you prefer narrower access.

In macOS System Settings, enable Mac Explorer. If it is missing, use **+** to add it; **Show App in Finder** locates the copy you are currently running. Authenticate with Touch ID or your Mac password when macOS asks, then quit and reopen the app. The app cannot grant itself permission or authenticate on your behalf. If the shortcut is unavailable, navigate manually to **System Settings → Privacy & Security → Full Disk Access**.

This release is ad hoc signed. Updating or rebuilding it can change the identity macOS uses to remember permissions, so authorization may be requested again. Full Disk Access does not resolve this signing limitation or provide Apple notarization.

## Troubleshooting

- **App blocked:** check the signing notice and Apple instructions in [Install](../README.md#install).
- **Folder cannot be read:** check the folder exists, the disk is connected, and macOS Files and Folders permissions permit access. Refresh after reconnecting a volume.
- **Language did not change:** quit Mac Explorer completely and reopen it. The language selection is in Mac Explorer → Settings. Regional formats are separate from the interface language.
- **Search seems outdated:** refresh with ⌘R. Monitoring of the open folder does not monitor every descendant in a recursive search.
- **Feature missing:** the [README limitations](../README.md#privacy-and-limitations) describe the current scope. Include app version, macOS version and reproducible steps in an issue, without personal file contents.
