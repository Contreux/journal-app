// journal-app/journal-app/Models/ActivityType.swift
// Defines all available activity types

import Foundation
import SwiftUI

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
        case .gym: return .red
        case .running: return .orange
        case .social: return .blue
        case .work: return .indigo
        case .sideProject: return .purple
        case .hobby: return .pink
        case .cleaning: return .cyan
        case .reading: return .brown
        case .meditation: return .green
        case .cooking: return .yellow
        case .commute: return .gray
        case .meeting: return .teal
        case .learning: return .mint
        case .rest: return .indigo.opacity(0.6)
        }
    }
}
