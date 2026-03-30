// journal-app/journal-app/Models/ActivityType.swift

import Foundation
import SwiftUI

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
    case rest = "Rest"

    var id: String { rawValue }

    var category: ActivityCategory {
        switch self {
        case .gym, .running, .meditation, .rest:
            return .body
        case .work, .sideProject, .learning, .reading:
            return .mind
        case .social, .cooking, .cleaning, .commute, .meeting, .hobby:
            return .life
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
        }
    }

    static var grouped: [(category: ActivityCategory, types: [ActivityType])] {
        ActivityCategory.allCases.map { cat in
            (category: cat, types: allCases.filter { $0.category == cat })
        }
    }
}
