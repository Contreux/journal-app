// journal-app/journal-app/journal_appApp.swift
// Main app entry point

import SwiftUI
import SwiftData

@main
struct journal_appApp: App {
    @State private var viewModel = ActivityTrackerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .modelContainer(for: [ActivitySession.self])
    }
}
