import AppKit
import SwiftUI

/// Installs a single behind-window glass base (`NSVisualEffectView`) and modern
/// window chrome (transparent titlebar, full-size content). All SwiftUI
/// `.glassEffect` surfaces float over this one base — no doubled materials.
///
/// Adapted from the Relay pattern. Deck targets macOS 26, so glass APIs are
/// unconditionally available; this just supplies the genuine behind-window glass.
struct GlassWindowBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active

        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.styleMask.insert(.fullSizeContentView)
            window.titlebarAppearsTransparent = true
            window.titlebarSeparatorStyle = .none
            window.titleVisibility = .hidden
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
