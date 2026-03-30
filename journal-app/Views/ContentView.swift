// journal-app/journal-app/Views/ContentView.swift
// Main tab view container with iOS 26 Control Center UI

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // New iOS 26 Control Center UI
            ControlCenterView()
                .tabItem {
                    Label("Control", systemImage: "switch.2")
                }
                .tag(0)
            
            ActivitiesView()
                .tabItem {
                    Label("Activities", systemImage: "list.bullet.rectangle")
                }
                .tag(1)
            
            CalendarView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ActivitySession.self, inMemory: true)
}
