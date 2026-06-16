# Building Deck

**Requirements:** macOS 26 (Tahoe) · **Xcode 26**.

The project is defined by `project.yml` (XcodeGen) so source files can be added
without hand-editing the `.xcodeproj`.

## One-time setup
```bash
cd /Users/clyde/Desktop/Tools/Deck
xcodegen generate     # produces Deck.xcodeproj from project.yml
open Deck.xcodeproj
```
Then in Xcode: select the **Deck** scheme → Run.

Re-run `xcodegen generate` any time files are added/removed.

## Command-line build/test
`xcode-select` on this machine points at CommandLineTools, so `xcodebuild` needs
Xcode pointed to explicitly (no sudo required):

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Deck.xcodeproj -scheme Deck -destination 'platform=macOS' build
# tests:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Deck.xcodeproj -scheme Deck -destination 'platform=macOS' test
```

## Notes
- Ad-hoc signed (`CODE_SIGN_IDENTITY = "-"`); first launch may need right-click → Open.
- Not sandboxed for v1. Bundle id `com.hatim.deck`. Deployment target macOS 26.0.
- Storage is local SwiftData (no sync). The store seeds a small example on first
  launch (`SeedData.swift`) — delete that call once you have real data, or wipe the
  store by removing `~/Library/Application Support/default.store*`.
