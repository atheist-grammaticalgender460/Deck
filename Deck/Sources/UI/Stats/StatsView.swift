import SwiftData
import SwiftUI

/// Activity overview: how much you've completed across time windows, plus totals
/// and a per-type breakdown. "Done" is measured by `Note.completedAt`.
struct StatsView: View {
    @Query private var notes: [Note]

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Text("Statistics")
                    .font(.largeTitle.bold())

                group("Completed") {
                    LazyVGrid(columns: columns, spacing: 14) {
                        statCard("Today", completed(within: .day), "sun.max.fill", .orange)
                        statCard("This Week", completed(within: .weekOfYear), "calendar", .blue)
                        statCard("This Month", completed(within: .month), "calendar.badge.clock", .purple)
                        statCard("This Year", completed(within: .year), "calendar.circle", .green)
                        statCard("Lifetime", lifetimeDone, "infinity", .pink)
                    }
                }

                group("Open work") {
                    LazyVGrid(columns: columns, spacing: 14) {
                        statCard("Pending", pending, "tray.full.fill", .orange)
                        statCard("Bugs open", openBugs, "ladybug.fill", .red)
                        statCard("Features open", openFeatures, "sparkles", .purple)
                    }
                }

                group("Shipped (lifetime)") {
                    LazyVGrid(columns: columns, spacing: 14) {
                        statCard("Bugs fixed", doneBugs, "checkmark.seal.fill", .red)
                        statCard("Features shipped", doneFeatures, "shippingbox.fill", .purple)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollContentBackground(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .all)
        .bottomScrollFade()
        .background(.clear)
        .navigationTitle("Statistics")
    }

    // MARK: Cards

    private func group<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).foregroundStyle(.secondary)
            content()
        }
    }

    private func statCard(_ title: String, _ value: Int, _ symbol: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(color.opacity(0.25)))
    }

    // MARK: Computations

    private var doneNotes: [Note] { notes.filter { $0.completedAt != nil } }
    private var lifetimeDone: Int { doneNotes.count }
    private var pending: Int { notes.filter { $0.status == .pending }.count }
    private var openBugs: Int { notes.filter { $0.status == .pending && $0.isBug }.count }
    private var openFeatures: Int { notes.filter { $0.status == .pending && $0.isFeature }.count }
    private var doneBugs: Int { doneNotes.filter { $0.isBug }.count }
    private var doneFeatures: Int { doneNotes.filter { $0.isFeature }.count }

    private func completed(within component: Calendar.Component) -> Int {
        let cal = Calendar.current
        let now = Date()
        return doneNotes.filter { note in
            guard let done = note.completedAt else { return false }
            return cal.isDate(done, equalTo: now, toGranularity: component)
        }.count
    }
}
