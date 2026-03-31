// journal-app/Models/JournalActivityAttributes.swift
// Shared between main app and widget extension

import ActivityKit
import SwiftUI

struct JournalActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedSeconds: Int
    }

    var activityName: String
    var activityIcon: String
    var colorHex: String
}
