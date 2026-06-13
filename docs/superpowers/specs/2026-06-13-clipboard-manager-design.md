# Clipboard Manager — Design

**Date:** 2026-06-13
**Working name:** ClipKeep (provisional; rename freely)
**Status:** Approved design, ready for implementation planning

## 1. Summary

A macOS menu-bar app that records clipboard history (plain text and images),
keeps that history searchable, and pastes any past item back into the app you
were using via a global hotkey popup. Items copied on an iPhone arrive
automatically through Apple's Universal Clipboard and are captured like any
other clip — no companion iOS app is built.

## 2. Goals

- Continuously capture plain-text and image clips, including iPhone clips that
  arrive via Universal Clipboard.
- Summon a fast, searchable, keyboard-driven popup with a global hotkey and
  paste the chosen item into the previously-focused app.
- Persist history across launches with sensible retention limits.
- Protect sensitive content (passwords) by default.
- Ship as a notarized, Developer ID–signed download (no App Store sandbox).

## 3. Non-goals (v1)

Deliberately excluded to keep scope tight; each is easy to add later:

- Pinning / favorites
- Rich-text or HTML clip capture (plain text only)
- File-reference or URL-specific handling
- iCloud sync of history between Macs
- An "from iPhone" source badge (see §6 for why this is unreliable)
- A companion iOS app

## 4. Distribution & platform constraints

- **Distribution:** notarized `.app` / `.dmg` via Developer ID (requires a paid
  Apple Developer account, $99/yr). Local build-and-run needs no account.
- **Not sandboxed.** This is required: background clipboard polling and
  Accessibility-based auto-paste are incompatible with the App Store sandbox.
- **Agent app:** `LSUIElement = true` (menu-bar only, no Dock icon).
- **Toolchain:** Swift 6.3, SwiftUI-first with thin AppKit bridges, targeting a
  current macOS release (Apple Silicon + Intel universal binary).

## 5. Architecture

A menu-bar agent process split into focused, independently-testable units.

### Components

- **ClipboardMonitor** — Watches the system pasteboard with *smart polling*
  (see §6). On a detected change it reads the content, applies the privacy
  filter, de-dupes, and hands the result to `HistoryStore`. Universal Clipboard
  items arrive through this same general pasteboard, so they need no special
  code path.
- **HistoryStore** — GRDB/SQLite persistence. A `clips` table plus an FTS5
  full-text index for instant search. Owns insert, de-dupe, search, and
  retention/pruning. Image bytes live as files on disk; the DB stores
  references only.
- **HotkeyManager** — Built on the `KeyboardShortcuts` library. On trigger it
  records the currently-frontmost app (the paste target), then shows the popup.
  Also provides the shortcut-recorder UI in Settings.
- **PopupPanel** — A non-activating `NSPanel` hosting a SwiftUI list view
  (Layout A, see §7). Appears without stealing focus from the current app.
- **PasteService** — Writes the selected clip to `NSPasteboard`, reactivates the
  recorded target app, and synthesizes ⌘V via `CGEvent`. Degrades to copy-only
  when Accessibility is unavailable.
- **PermissionsCoordinator** — Checks/requests Accessibility, drives onboarding,
  detects later revocation.
- **Settings / Onboarding** — Shortcut, retention, privacy, launch-at-login.

### Data flow

1. User copies (locally or via Universal Clipboard from iPhone) → the system
   pasteboard `changeCount` increments.
2. `ClipboardMonitor` detects the change, reads content, runs the privacy
   filter, de-dupes, and writes to `HistoryStore` (text row, or image file +
   thumbnail + row).
3. User presses the global hotkey → `HotkeyManager` records the frontmost app
   and shows `PopupPanel` over the current app.
4. User searches / navigates and selects → `PasteService` sets the pasteboard,
   refocuses the recorded app, and sends ⌘V.

## 6. Clipboard capture

### Why polling, and why "smart"

macOS exposes no event/notification API for the general pasteboard — there is
no change notification and `changeCount` is not KVO-observable. A `CGEventTap`
on ⌘C is not a viable substitute because it misses menu/programmatic/screenshot
copies and, critically, **Universal Clipboard pushes from iPhone (no local
keystroke occurs)**. Polling `changeCount` is the standard, Apple-tolerated
approach used by every clipboard manager.

Polling is cheap because `changeCount` is a single integer read; the expensive
work (reading contents) happens only on the rare ticks where the count actually
moved. Reading `changeCount` does **not** trigger a Universal Clipboard network
fetch — only reading contents can, and we only read contents on a real change.

**Smart-polling refinements:**

- **Adaptive interval** — ~0.3s while the user is active, backing off to ~1s
  when idle. Universal Clipboard latency plus the item persisting on the
  pasteboard means a 1s poll still catches iPhone copies.
- **Pause on sleep/lock** — stop the timer on `NSWorkspace.willSleep` and
  screen-lock; resume on `didWake`.
- **Off the main thread** — a `DispatchSourceTimer` on a background queue so UI
  responsiveness is never affected.
- **changeCount-gated reads** — contents are read only when the count moved.

### Content types

- **Text:** `public.utf8-plain-text` → stored as full `text` plus a ~200-char
  `preview`.
- **Image:** prefer `public.png`, fall back to `public.tiff` → written to disk
  as PNG with a downscaled JPEG thumbnail. Images above a configurable size cap
  (default 50 MB) are skipped.

### Privacy filter (on by default)

- Skip any pasteboard item declaring `org.nspasteboard.ConcealedType` (used by
  password managers / Keychain), `org.nspasteboard.TransientType`, or
  `org.nspasteboard.AutoGeneratedType`.
- User-editable **app-exclusion list**: skip clips captured while an excluded
  app (e.g., a password manager) was frontmost. Source app is captured as
  `sourceBundleID` at copy time.
- Global **Pause** toggle in the menu bar.

### iPhone source labeling

Universal Clipboard items carry no public, documented marker identifying them
as iPhone-originated. Capture is automatic and reliable; *labeling* is not. v1
shows time only and omits a source badge rather than display one that is
sometimes wrong.

## 7. Popup UI (Layout A — compact list)

- A narrow, dense floating panel summoned at the global hotkey, centered on the
  active screen, that does not steal focus.
- **Search field** at the top, auto-focused; typing filters via FTS5 instantly.
- **Vertical list** of clips. Each row: quick-select index (1–9), a type icon or
  inline image thumbnail, a single-line content preview, and a relative time.
- **Image rows** show a small inline thumbnail; text rows show the preview.
- **Keyboard:** ↑/↓ to move, ↵ to paste, ⌘1–⌘9 to paste a numbered item
  directly, ⌥↵ to copy without auto-pasting, ⌫ to delete the highlighted entry,
  esc to dismiss. Mouse selection also supported.
- No dedicated preview pane in v1 (Layout B was considered and declined).

## 8. Persistence & data model

GRDB/SQLite. Single `clips` table:

| Column           | Notes                                                        |
|------------------|--------------------------------------------------------------|
| `id`             | primary key                                                  |
| `kind`           | `text` \| `image`                                            |
| `text`           | full text (text clips)                                       |
| `preview`        | first ~200 chars (text clips)                                |
| `imagePath`      | file reference (image clips)                                 |
| `thumbPath`      | downscaled thumbnail (image clips)                           |
| `width`,`height` | image dimensions (image clips)                               |
| `byteSize`       | image size in bytes (image clips)                            |
| `contentHash`    | for de-duplication                                           |
| `sourceBundleID` | best-effort frontmost app at copy time (not displayed in v1) |
| `createdAt`      | capture time                                                 |
| `lastUsedAt`     | updated on re-copy / paste                                   |

- **FTS5** virtual table mirrors `text` + `preview`, synced via triggers.
- **Image files:** `~/Library/Application Support/<app>/images/<uuid>.png`;
  thumbnails in a sibling `thumbs/` directory.
- **De-duplication:** on capture, hash the content; if it equals the most recent
  clip, bump `lastUsedAt` and move it to the top instead of inserting a copy.

### Retention (all configurable)

- Keep the last **500** clips **or 30 days**, whichever is smaller.
- Image-store cap **1 GB**.
- Oldest entries beyond the limits are pruned — with their image files — on
  insert and on a periodic sweep.

## 9. Paste mechanism & permissions

- **Paste:** write the selected clip to `NSPasteboard` → close the panel →
  reactivate the app that was frontmost when the hotkey fired → post a
  synthetic ⌘V (`CGEvent` key down/up with the Command flag).
- **Copy-only:** ⌥↵ writes to the pasteboard without auto-pasting.
- **Accessibility:** auto-paste requires Accessibility permission
  (`AXIsProcessTrusted`). First-run onboarding explains why and opens the
  correct System Settings pane. If permission is missing or later revoked, the
  app degrades to copy-only and surfaces a hint.
- **Launch at login:** `SMAppService.register()`, toggleable in Settings.
- **Menu-bar menu:** Open History, Settings, Pause, Quit.

## 10. Settings

- **Global shortcut** — `KeyboardShortcuts` recorder.
- **Retention** — max items, max age, max image-store size.
- **Privacy** — respect concealed types (default on), app-exclusion list, Pause.
- **Launch at login** — toggle.
- **Clear history** — destructive action with confirmation.

## 11. Error handling

- DB or capture errors are logged and swallowed — a capture failure must never
  crash the agent or interrupt monitoring.
- Image decode/write failures skip that entry.
- Oversized or unknown pasteboard payloads are guarded by size checks.
- Accessibility revocation is detected and switches the app to copy-only.

## 12. Testing

- **HistoryStore** — unit tests for insert, de-dupe, search, and prune against
  an in-memory SQLite database.
- **Privacy filter** — unit tests over synthetic pasteboard items
  (concealed/transient/excluded-app cases).
- **Capture pipeline** — the pasteboard sits behind a protocol so the monitor's
  logic is tested without touching the real system clipboard.
- **Hotkey → paste** — documented manual test plan (synthetic `CGEvent` paste
  is not unit-testable); verify against TextEdit, a browser, and an image
  editor, and verify graceful copy-only fallback when Accessibility is denied.

## 13. Dependencies

- **GRDB.swift** (MIT) — SQLite persistence + FTS5 full-text search.
- **KeyboardShortcuts** (MIT) — user-customizable global hotkey + recorder UI.

Both are de-facto standards in the macOS indie ecosystem, statically linked
into the app bundle.

## 14. Open follow-ups (post-v1)

Pinning/favorites, rich-text/file capture, multi-Mac iCloud sync, and a
reliable iPhone source indicator if a dependable signal emerges.
