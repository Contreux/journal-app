// journal-app/journal-app/Views/ContentView.swift
// Main tab view with iOS 26 design

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            ActivitiesView()
                .tabItem {
                    Label("Track", systemImage: "play.circle.fill")
                }

            CalendarView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(ActivityTrackerViewModel())
        .modelContainer(for: ActivitySession.self, inMemory: true)
}
