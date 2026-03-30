// journal-app/journal-app/Models/ActivitySession.swift
// SwiftData model for tracked activity sessions

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
    
    var icon: String {
        activityTypeEnum.icon
    }
    
    var color: Color {
        activityTypeEnum.color
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        endTime == nil
    }
    
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
