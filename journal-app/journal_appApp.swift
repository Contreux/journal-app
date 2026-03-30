// journal-app/journal-app/journal_appApp.swift

import SwiftUI
import SwiftData

@main
struct journal_appApp: App {
    @State private var viewModel = ActivityTrackerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .tint(Color(red: 0.95, green: 0.55, blue: 0.25))
        }
        .modelContainer(for: [ActivitySession.self])
    }
}
