# Changelog

## 1.1.1
- The Bug and Feature pills are now fully clickable — anywhere on the pill toggles it, not just the text.

## 1.1.0
- Fixed the lag when a note contains a picture: the editor no longer re-encodes and re-saves the whole note (images included) on every keystroke. Saving is now debounced, so typing stays smooth and the image is encoded only when you pause or leave the note.
- Notes are now ordered newest-created first by default, so editing an old note no longer jumps it to the top. You can switch back to "Recently edited first" in Settings → General → Notes.

## 1.0.11
- Turned off autocorrect, spelling/grammar squiggles, and smart quote/dash substitutions in the editor, so mixed French/English notes are left exactly as typed.

## 1.0.10
- Note previews no longer show the bullet marker or the big gap after it — list notes preview as clean text.

## 1.0.9
- Settings now show just the version number (e.g. 1.0.9), without the internal build number in parentheses.

## 1.0.8
- The editor font and size are now truly locked — pasted text (even tiny or monospace fonts) is always shown in the one body font, and opening older notes corrects them too. Your bold/italic is kept.

## 1.0.7
- The number next to each category in the sidebar now shows open (pending) bugs and features instead of the project count — it reads 0 when nothing's open.

## 1.0.6
- Deleting a bullet is now one press: with the cursor in front of the words, Delete removes the whole bullet (outdenting a nested one a tier at a time) instead of first deleting just the indent and then the dot.

## 1.0.5
- Type "- " (dash + space) at the start of a line to begin a bullet list, just like Apple Notes.
- Bullet lists now support tiers — press Tab to nest a bullet deeper and Shift+Tab to move it back out.
- Return continues the list; pressing Return on an empty bullet outdents it, then leaves the list.

## 1.0.4
- Pasted text now actually shrinks to the editor's normal body size — big headings and large fonts copied from Apple Notes no longer come in oversized. (The previous clean-paste fix wasn't being applied to the pasted range.)

## 1.0.3
- Paste is now always clean: every paste strips incoming colors and formatting and uses the editor's own readable style (like Paste and Match Style), so text from Apple Notes is never black or unreadable. Inline images are still kept.
- Fixed the bug where, after pasting, new typing stayed black even after deleting everything — the typing style is now reset after each paste.
- Existing notes with baked-in black text now render in the readable label color too.

## 1.0.2
- Note title is now a dedicated, freely-editable field (it no longer auto-fills from the first line).
- Pasting from Apple Notes stays readable — text no longer turns black on the dark editor.
- Added Paste and Match Style (⌃⇧V) to paste text without any formatting.
- Deleting notes is smooth now — no more jiggle or stutter.
- The category Theme menu shows real color swatches, and the Edit sheet has the full color grid.
- Drag categories in the sidebar to reorder them, Apple-Notes style.
- New "What's New" tab in Settings so you can always see what changed.

## 1.0.1
- Maintenance release — verifies the in-app update flow end to end. No feature changes.

## 1.0
- First release of Deck — a local, native macOS tracker for your projects' bugs, features, and ideas.
- Dashboard of project cards grouped by category, each with live pending/done and bug/feature counts.
- Three-pane project view: categories → notes → rich-text editor (bullets, images, copy/export).
- Lift-to-complete drag-and-drop: grab a note, the screen blurs, drop it on Done or Delete.
- Stats page: completed today / this week / month / year / lifetime.
- Search across every note; Bug + Feature tags (a note can be both) with a Both filter.
- Liquid Glass throughout, per-category color themes, soft scroll edges.
- Local-only storage with automatic on-launch backups — your data never leaves the Mac.
- In-app manual updates from GitHub (you're always in control of when to install).
