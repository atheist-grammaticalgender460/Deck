import Foundation
import SwiftData
import SwiftUI

// MARK: - Enums

enum Status: String, Codable, CaseIterable, Identifiable {
    case pending, done
    var id: String { rawValue }
    var label: String { self == .pending ? "Pending" : "Done" }
}

enum ItemType: String, Codable, CaseIterable, Identifiable {
    case bug, feature
    var id: String { rawValue }

    var label: String {
        switch self {
        case .bug: return "Bug"
        case .feature: return "Feature"
        }
    }

    var symbol: String {
        switch self {
        case .bug: return "ladybug"
        case .feature: return "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .bug: return .red
        case .feature: return .purple
        }
    }
}

/// Note-list type filter, including a "Both" option for combined bug+feature notes.
enum NoteTypeFilter: String, CaseIterable, Identifiable {
    case all, bug, feature, both
    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .bug: return "Bug"
        case .feature: return "Feature"
        case .both: return "Both"
        }
    }

    func matches(_ note: Note) -> Bool {
        switch self {
        case .all: return true
        case .bug: return note.isBug
        case .feature: return note.isFeature
        case .both: return note.isBug && note.isFeature
        }
    }
}

// MARK: - Models

@Model
final class Category {
    var name: String
    /// Glass-tint theme, e.g. "blue" / "green" / "red". See `CategoryTheme`.
    var themeRaw: String
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Project.category)
    var projects: [Project]

    var theme: CategoryTheme {
        get { CategoryTheme(rawValue: themeRaw) ?? .blue }
        set { themeRaw = newValue.rawValue }
    }

    init(name: String, theme: CategoryTheme = .blue, sortOrder: Int = 0, createdAt: Date = Date()) {
        self.name = name
        self.themeRaw = theme.rawValue
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.projects = []
    }
}

@Model
final class Project {
    var name: String
    var emoji: String?
    var colorHex: String?
    var sortOrder: Int
    var isArchived: Bool
    var createdAt: Date

    var category: Category?

    @Relationship(deleteRule: .cascade, inverse: \Note.project)
    var notes: [Note]

    init(name: String,
         emoji: String? = nil,
         colorHex: String? = nil,
         sortOrder: Int = 0,
         isArchived: Bool = false,
         createdAt: Date = Date()) {
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.notes = []
    }

    // MARK: Derived counts

    var pendingCount: Int { notes.filter { $0.status == .pending }.count }
    var doneCount: Int { notes.filter { $0.status == .done }.count }

    /// open/closed counts for a given type, e.g. (1, 4) → 1 pending, 4 done bugs.
    func counts(for type: ItemType) -> (pending: Int, done: Int) {
        let typed = notes.filter { $0.has(type) }
        return (typed.filter { $0.status == .pending }.count,
                typed.filter { $0.status == .done }.count)
    }
}

@Model
final class Note {
    var title: String
    /// Archived NSAttributedString (RTFD). Inline images live inside this blob.
    var contentRTFD: Data?
    var statusRaw: String
    /// A note can be a bug, a feature, or BOTH (counts toward each statistic).
    var isBug: Bool
    var isFeature: Bool
    var createdAt: Date
    var updatedAt: Date
    /// When the note was marked done (nil while pending). Drives the stats page.
    var completedAt: Date?

    var project: Project?

    var status: Status {
        get { Status(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    /// Active types, in display order — used for the row icons.
    var types: [ItemType] {
        var result: [ItemType] = []
        if isBug { result.append(.bug) }
        if isFeature { result.append(.feature) }
        return result.isEmpty ? [.feature] : result
    }

    var activeTypeCount: Int { (isBug ? 1 : 0) + (isFeature ? 1 : 0) }

    func has(_ type: ItemType) -> Bool {
        switch type {
        case .bug: return isBug
        case .feature: return isFeature
        }
    }

    func set(_ type: ItemType, _ on: Bool) {
        switch type {
        case .bug: isBug = on
        case .feature: isFeature = on
        }
    }

    init(title: String = "",
         contentRTFD: Data? = nil,
         status: Status = .pending,
         isBug: Bool = false,
         isFeature: Bool = true,
         createdAt: Date = Date()) {
        self.title = title
        self.contentRTFD = contentRTFD
        self.statusRaw = status.rawValue
        self.isBug = isBug
        self.isFeature = isFeature
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.completedAt = (status == .done) ? createdAt : nil
    }

    /// Single place to change status so `completedAt`/`updatedAt` stay correct.
    func setStatus(_ newStatus: Status, now: Date = Date()) {
        status = newStatus
        completedAt = (newStatus == .done) ? now : nil
        updatedAt = now
    }
}
