# Deck — Spec

A local-only macOS app for tracking app/project updates: bugs, features, and ideas.
A bird's-eye dashboard of every project you're working on, with per-project counts of
what's pending vs done — replacing the messy Apple Notes folder setup.

**Not** to be confused with Folio (a separate book-writing tool). Deck is for planning
and tracking work on your own projects.

---

## Problem it solves

Today, project updates live in Apple Notes as `Project > Pending / Done` subfolders.
Failure modes:
- Parent folders show no rollup — you can't see total updates for an app at a glance.
- Counts are per-leaf-folder only; no "X pending across the project."
- No way to slice by who the work is for (personal / work / wife / a named person).
- No distinction between a bug, a feature, and an idea.

## Core principles

- **Local only.** No server, no account, no required sync. Data lives on this Mac.
- **Minimal.** Bullet lists, checkboxes, inline images, faithful copy/export. Nothing else.
- **Bird's-eye first.** The home screen is a grid of project cards with live counts.
- Optional iCloud sync is a *future* toggle, not a v1 dependency.

---

## Data model (SwiftData)

Three levels: **Category → Project → Note**.

### Category
The top-level grouping — usually a person or area of life.
Examples: Personal, Work, Wife, Kamal, ViralFactory.
- `id`
- `name`
- `colorHex` (optional, for visual grouping)
- `sortOrder`
- `projects: [Project]` (one-to-many)

### Project
An app or piece of work. Rendered as a card on the dashboard.
- `id`
- `name`
- `emoji` / `colorHex` (optional, for card identity)
- `sortOrder`
- `isArchived` (hide finished projects without deleting)
- `category: Category` (parent)
- `notes: [Note]` (one-to-many)
- Derived (computed from notes): counts by status × type.

### Note
A single update/item. The unit you count.
- `id`
- `title`
- `contentRTFD: Data` — archived NSAttributedString (RTFD; inline images live here)
- `status: Status` — `.pending` | `.done`
- `type: ItemType` — `.bug` | `.feature` | `.idea`
- `createdAt`, `updatedAt`
- `project: Project` (parent)

### Enums
```swift
enum Status: String, Codable, CaseIterable { case pending, done }
enum ItemType: String, Codable, CaseIterable { case bug, feature, idea }
```

---

## Screens

### 1. Dashboard (home)
Grid of project cards, optionally grouped by Category (collapsible sections).
Each **card** shows:
- Project name + emoji/color.
- Pending vs done summary, e.g. `5 pending · 12 done`.
- Optional per-type breakdown chip: `🐞 1/4  ✨ 2/1  💡 1` (open/closed).
- Click → opens the project's note list.

Top-level filter: by Category (All / Work / Personal / …).

### 2. Project view
List of notes for one project. Inspired by Apple Notes' middle column.
- Filter/segment: All · Pending · Done, and by type.
- Each row: title, snippet, type badge, status toggle, date.
- Toggle a note pending↔done inline. Counts on the card update live.
- "+" to add a note.

### 3. Note editor
Apple-Notes-style rich text (RTFD), right pane.
- Bullet lists, checkboxes, bold/italic, headings.
- Inline image insertion (paste or drag-drop).
- **Copy / export with formatting intact** (RTFD/RTF to clipboard; image-safe).
- Set status (pending/done) and type (bug/feature/idea) from the editor.

---

## Editor (the one non-trivial piece)

Native rich text via `NSTextView` wrapped in `NSViewRepresentable` (not SwiftUI's
`TextEditor`, which can't do inline images / RTFD round-tripping reliably).

- Content persisted as RTFD `Data` (`NSAttributedString` → `rtfd(...)`), same format
  Apple Notes uses under the hood. Inline images are embedded in the RTFD, so no
  separate asset management needed for v1.
- Copy-out uses the standard responder chain so paste into Mail/Notes keeps formatting.
- Export menu: copy as RTF, or "Export…" to an `.rtfd` / `.pdf` file.

---

## Tech

- SwiftUI + AppKit (NSTextView bridge), SwiftData for persistence.
- macOS 26 (Tahoe), Xcode 26, Swift 5. Apple-Silicon-first, universal binary.
- XcodeGen (`project.yml`) so files can be added without hand-editing the pbxproj.
- Ad-hoc signed, **not** sandboxed initially (sandbox can come with notarization later).
- Bundle id `com.hatim.deck`.

## Out of scope for v1

- Cloud sync / backup (future iCloud toggle — SwiftData makes this a small change).
- Apple Notes import (proprietary store; manual re-entry for now).
- Tags beyond category/type, collaboration, reminders, search ranking, themes.

## Build

```bash
cd /Users/clyde/Desktop/Tools/Deck
xcodegen generate
open Deck.xcodeproj   # select Deck scheme → Run
```
