import QuartzCore
import SwiftData
import SwiftUI

// MARK: - Drop targets (drag is ONLY for completing/deleting — moving is right-click)

enum DropKind: Equatable {
    case markDone
    case markPending
    case delete
}

struct DropTargetFrame: Equatable {
    let id: String
    let kind: DropKind
    let rect: CGRect
}

struct DropTargetKey: PreferenceKey {
    static let defaultValue: [DropTargetFrame] = []
    static func reduce(value: inout [DropTargetFrame], nextValue: () -> [DropTargetFrame]) {
        value.append(contentsOf: nextValue())
    }
}

private struct DropTargetModifier: ViewModifier {
    let id: String
    let kind: DropKind
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: DropTargetKey.self,
                    value: [DropTargetFrame(id: id, kind: kind, rect: geo.frame(in: .global))]
                )
            }
        )
    }
}

extension View {
    func dropTarget(_ id: String, kind: DropKind) -> some View {
        modifier(DropTargetModifier(id: id, kind: kind))
    }

    /// Attaches the lift-to-complete drag to any note row (list or search result).
    func noteDragGesture(_ note: Note, _ drag: DragController, _ context: ModelContext,
                         onCommit: @escaping ((DropKind, Note)?) -> Void = { _ in }) -> some View {
        opacity(drag.draggedNote === note ? 0.3 : 1)
            .gesture(
                DragGesture(minimumDistance: 12, coordinateSpace: .global)
                    .onChanged { value in
                        if drag.draggedNote == nil { drag.begin(note, at: value.location) }
                        drag.update(to: value.location)
                    }
                    .onEnded { _ in onCommit(drag.commit(context: context)) }
            )
    }
}

// MARK: - Controller

@MainActor
final class DragController: ObservableObject {
    @Published var draggedNote: Note?
    @Published var location: CGPoint = .zero
    @Published var velocity: CGVector = .zero
    @Published private(set) var hovered: String?
    var targets: [DropTargetFrame] = []

    private var lastLocation: CGPoint = .zero
    private var lastTime: CFTimeInterval?

    private let captureRadius: CGFloat = 150
    let reactRadius: CGFloat = 240

    var isActive: Bool { draggedNote != nil }

    func begin(_ note: Note, at point: CGPoint) {
        draggedNote = note
        location = point
        lastLocation = point
        lastTime = nil
        velocity = .zero
        hovered = nil
    }

    func update(to point: CGPoint) {
        let now = CACurrentMediaTime()
        if let last = lastTime {
            let dt = max(now - last, 1.0 / 240.0)
            let vx = (point.x - lastLocation.x) / dt
            let vy = (point.y - lastLocation.y) / dt
            velocity = CGVector(dx: velocity.dx * 0.4 + vx * 0.6, dy: velocity.dy * 0.4 + vy * 0.6)
        }
        lastTime = now
        lastLocation = point
        location = point

        var bestID: String?
        var bestDist = CGFloat.greatestFiniteMagnitude
        for target in targets {
            if target.rect.contains(point) { bestID = target.id; bestDist = 0; break }
            let c = CGPoint(x: target.rect.midX, y: target.rect.midY)
            let d = hypot(point.x - c.x, point.y - c.y)
            if d < bestDist { bestDist = d; bestID = target.id }
        }
        let snapped = bestDist <= captureRadius ? bestID : nil
        if snapped != hovered { hovered = snapped }
    }

    func reaction(for id: String) -> CGFloat {
        if hovered == id { return 1 }
        guard let t = targets.first(where: { $0.id == id }) else { return 0 }
        let c = CGPoint(x: t.rect.midX, y: t.rect.midY)
        let d = hypot(location.x - c.x, location.y - c.y)
        return max(0, 1 - d / reactRadius) * 0.7
    }

    func pull(for id: String, limit: CGFloat = 10) -> CGSize {
        guard let t = targets.first(where: { $0.id == id }) else { return .zero }
        let c = CGPoint(x: t.rect.midX, y: t.rect.midY)
        let dx = location.x - c.x, dy = location.y - c.y
        let dist = Swift.max(hypot(dx, dy), 1)
        let amount = reaction(for: id) * limit
        return CGSize(width: dx / dist * amount, height: dy / dist * amount)
    }

    private func currentKind() -> DropKind? {
        guard let id = hovered else { return nil }
        return targets.first { $0.id == id }?.kind
    }

    /// Performs the drop and returns what happened (so callers can clear selection).
    func commit(context: ModelContext) -> (DropKind, Note)? {
        let kind = currentKind()
        let note = draggedNote
        // Don't wrap this in withAnimation: RootView already animates on
        // `drag.isActive`, and animating it here too makes the drop flicker twice.
        clear()
        guard let note, let kind else { return nil }
        switch kind {
        case .markDone: note.setStatus(.done)
        case .markPending: note.setStatus(.pending)
        case .delete: context.delete(note)
        }
        try? context.save()
        return (kind, note)
    }

    func clear() {
        draggedNote = nil
        hovered = nil
        velocity = .zero
        targets = []
    }
}

// MARK: - Overlay (two big, beautiful targets — no scroll, nothing clipped)

struct DragOverlay: View {
    @EnvironmentObject private var drag: DragController
    @State private var appeared = false

    private var draggedIsDone: Bool { drag.draggedNote?.status == .done }

    var body: some View {
        ZStack {
            Color.black.opacity(0.32).ignoresSafeArea()

            VStack(spacing: 34) {
                Text(draggedIsDone ? "Reopen, or delete" : "Mark done, or delete")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(radius: 8)

                HStack(spacing: 44) {
                    if draggedIsDone {
                        target(id: "done", kind: .markPending, title: "Reopen",
                               systemImage: "arrow.uturn.left.circle.fill", color: .orange, index: 0)
                    } else {
                        target(id: "done", kind: .markDone, title: "Done",
                               systemImage: "checkmark.circle.fill", color: .green, index: 0)
                    }
                    target(id: "delete", kind: .delete, title: "Delete",
                           systemImage: "trash.fill", color: .red, index: 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ghost
        }
        .onPreferenceChange(DropTargetKey.self) { drag.targets = $0 }
        .onAppear { withAnimation(.spring(response: 0.42, dampingFraction: 0.7)) { appeared = true } }
        .onDisappear { appeared = false }
    }

    private func target(id: String, kind: DropKind, title: String,
                        systemImage: String, color: Color, index: Int) -> some View {
        let r = drag.reaction(for: id)
        return VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .semibold))
            Text(title)
                .font(.title3.weight(.semibold))
        }
        .foregroundStyle(r > 0.99 ? .white : color)
        .frame(width: 180, height: 140)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 24))
        .background(color.opacity(0.18 + r * 0.62), in: .rect(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(color.opacity(0.4 + r * 0.6), lineWidth: 1.5 + r * 2)
        )
        // Glow lives in a full-screen ZStack with empty space around it → never clipped.
        .shadow(color: color.opacity(0.25 + r * 0.6), radius: 20 + r * 38, y: 6)
        .scaleEffect(1 + r * 0.08)
        .offset(drag.pull(for: id))
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.66), value: r)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: drag.location)
        .animation(.spring(response: 0.44, dampingFraction: 0.7).delay(Double(index) * 0.05), value: appeared)
        .dropTarget(id, kind: kind)
    }

    @ViewBuilder
    private var ghost: some View {
        if let note = drag.draggedNote {
            let tilt = max(-10, min(10, drag.velocity.dx * 0.010))
            let speed = min(1, hypot(drag.velocity.dx, drag.velocity.dy) / 2600)
            HStack(spacing: 9) {
                TypeIcons(note: note)
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.callout.weight(.semibold)).lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.3)))
            .shadow(color: .black.opacity(0.4), radius: 16 + speed * 8, y: 7 + speed * 5)
            .scaleEffect(x: 1.04 + speed * 0.03, y: 1.04 - speed * 0.02, anchor: .center)
            .rotationEffect(.degrees(tilt), anchor: .top)
            .position(x: drag.location.x, y: drag.location.y - 24)
            .allowsHitTesting(false)
            .animation(.spring(response: 0.26, dampingFraction: 0.82), value: drag.location)
        }
    }
}
