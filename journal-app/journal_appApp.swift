// journal-app/journal-app/journal_appApp.swift
// Main app entry point

import SwiftUI
import SwiftData

@main
struct journal_appApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ActivitySession.self])
    }
}
