// journal-app/journal-app/Views/ContentView.swift
// Main tab view container

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ActivitiesView()
                .tabItem {
                    Label("Activities", systemImage: "list.bullet.rectangle")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ActivitySession.self, inMemory: true)
}
