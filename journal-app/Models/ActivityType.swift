// journal-app/journal-app/Models/ActivityType.swift

import Foundation
import SwiftUI
import SwiftData

// MARK: - Color Hex Helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - ActivityCategory

enum ActivityCategory: String, CaseIterable, Identifiable {
    case body = "Body"
    case mind = "Mind"
    case life = "Life"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .body: return "figure.stand"
        case .mind: return "brain.head.profile"
        case .life: return "house.fill"
        }
    }
}

// MARK: - ActivityType

enum ActivityType: String, CaseIterable, Identifiable {
    case gym = "Gym"
    case running = "Running"
    case social = "Social"
    case work = "Work"
    case sideProject = "Side Project"
    case hobby = "Hobby"
    case cleaning = "Cleaning"
    case reading = "Reading"
    case meditation = "Meditation"
    case cooking = "Cooking"
    case commute = "Commute"
    case meeting = "Meeting"
    case learning = "Learning"
    case rest = "Sleep"
    case relax = "Relax"

    var id: String { rawValue }

    var category: ActivityCategory {
        switch self {
        case .gym, .running, .meditation, .rest, .relax: return .body
        case .work, .sideProject, .learning, .reading, .meeting: return .mind
        case .social, .cooking, .cleaning, .commute, .hobby: return .life
        }
    }

    var icon: String {
        switch self {
        case .gym: return "dumbbell.fill"
        case .running: return "figure.run"
        case .social: return "person.2.fill"
        case .work: return "briefcase.fill"
        case .sideProject: return "hammer.fill"
        case .hobby: return "paintbrush.fill"
        case .cleaning: return "sparkles"
        case .reading: return "book.fill"
        case .meditation: return "leaf.fill"
        case .cooking: return "fork.knife"
        case .commute: return "car.fill"
        case .meeting: return "person.3.fill"
        case .learning: return "graduationcap.fill"
        case .rest: return "bed.double.fill"
        case .relax: return "figure.mind.and.body"
        }
    }

    var color: Color {
        switch self {
        case .gym: return Color(red: 0.90, green: 0.30, blue: 0.30)
        case .running: return Color(red: 0.95, green: 0.50, blue: 0.35)
        case .social: return Color(red: 0.35, green: 0.55, blue: 0.90)
        case .work: return Color(red: 0.40, green: 0.40, blue: 0.70)
        case .sideProject: return Color(red: 0.65, green: 0.40, blue: 0.75)
        case .hobby: return Color(red: 0.85, green: 0.50, blue: 0.60)
        case .cleaning: return Color(red: 0.40, green: 0.72, blue: 0.72)
        case .reading: return Color(red: 0.65, green: 0.50, blue: 0.38)
        case .meditation: return Color(red: 0.45, green: 0.70, blue: 0.50)
        case .cooking: return Color(red: 0.90, green: 0.70, blue: 0.30)
        case .commute: return Color(red: 0.60, green: 0.58, blue: 0.56)
        case .meeting: return Color(red: 0.30, green: 0.60, blue: 0.68)
        case .learning: return Color(red: 0.35, green: 0.62, blue: 0.45)
        case .rest: return Color(red: 0.62, green: 0.55, blue: 0.80)
        case .relax: return Color(red: 0.75, green: 0.62, blue: 0.85)
        }
    }

    static var grouped: [(category: ActivityCategory, types: [ActivityType])] {
        ActivityCategory.allCases.map { cat in
            (category: cat, types: allCases.filter { $0.category == cat })
        }
    }
}

// MARK: - CustomActivityType

@Model
class CustomActivityType {
    var name: String
    var symbol: String
    var colorHex: String
    var categoryName: String
    var sortOrder: Int

    init(name: String, symbol: String, colorHex: String, categoryName: String, sortOrder: Int = 0) {
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.categoryName = categoryName
        self.sortOrder = sortOrder
    }

    var color: Color { Color(hex: colorHex) }
    var category: ActivityCategory { ActivityCategory(rawValue: categoryName) ?? .life }
}

// MARK: - Symbol & Color Palettes

enum ActivitySymbolPalette {
    static let all: [(label: String, symbols: [String])] = [
        ("Body", ["figure.run", "dumbbell.fill", "bicycle", "figure.yoga", "figure.walk",
                  "heart.fill", "lungs.fill", "figure.dance", "figure.swimming",
                  "sportscourt.fill", "trophy.fill", "stopwatch.fill"]),
        ("Mind", ["brain.head.profile", "book.fill", "pencil", "laptopcomputer",
                  "lightbulb.fill", "music.note", "paintbrush.fill", "camera.fill",
                  "graduationcap.fill", "newspaper.fill", "mic.fill", "headphones"]),
        ("Life", ["house.fill", "car.fill", "fork.knife", "cart.fill", "airplane",
                  "pawprint.fill", "leaf.fill", "flame.fill", "moon.fill", "umbrella.fill",
                  "bag.fill", "phone.fill", "gamecontroller.fill", "tv.fill",
                  "wrench.fill", "hammer.fill", "cross.fill", "map.fill"])
    ]
}

enum ActivityColorPalette {
    static let colors: [(name: String, hex: String)] = [
        ("Red",    "E84B3A"),
        ("Orange", "F26A2E"),
        ("Amber",  "E8A020"),
        ("Yellow", "D4B800"),
        ("Green",  "3DAB5E"),
        ("Teal",   "2E9E8E"),
        ("Cyan",   "2E86C0"),
        ("Blue",   "3355CC"),
        ("Indigo", "5040B8"),
        ("Purple", "8040C0"),
        ("Pink",   "D44080"),
        ("Brown",  "8E6040"),
    ]
}
