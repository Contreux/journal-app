// journal-app/journal-app/Models/ActivitySession.swift

import Foundation
import SwiftData
import SwiftUI

@Model
class ActivitySession {
    var id: UUID
    var activityType: String
    var startTime: Date
    var endTime: Date?
    var summary: String?

    init(activityType: ActivityType, startTime: Date = Date()) {
        self.id = UUID()
        self.activityType = activityType.rawValue
        self.startTime = startTime
    }

    var activityTypeEnum: ActivityType {
        ActivityType(rawValue: activityType) ?? .work
    }

    var icon: String { activityTypeEnum.icon }
    var color: Color { activityTypeEnum.color }

    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var isActive: Bool { endTime == nil }

    var compactDuration: String {
        let total = Int(duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "< 1m"
    }

    var formattedDuration: String {
        let total = Int(duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    func resolvedType(customTypes: [CustomActivityType]) -> (name: String, icon: String, color: Color) {
        if let builtin = ActivityType(rawValue: activityType) {
            return (builtin.rawValue, builtin.icon, builtin.color)
        }
        if let custom = customTypes.first(where: { $0.name == activityType }) {
            return (custom.name, custom.symbol, custom.color)
        }
        return (activityType, "circle.fill", .gray)
    }

    var formattedTimeRange: String {
        let f = DateFormatter()
        f.timeStyle = .short
        let start = f.string(from: startTime)
        if let end = endTime {
            return "\(start) – \(f.string(from: end))"
        }
        return "\(start) – now"
    }
}
