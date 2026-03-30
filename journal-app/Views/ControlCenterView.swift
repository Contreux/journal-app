// ControlCenterView.swift
// iOS 26-inspired Control Center UI for the journal app

import SwiftUI
import SwiftData

struct ControlCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivitySession.startTime, order: .reverse) private var sessions: [ActivitySession]
    
    @State private var showingActivityPicker = false
    @State private var selectedActivity: ActivityType?
    @State private var currentSession: ActivitySession?
    
    // iOS 26 glassmorphism colors
    private let cardBackground = Color.white.opacity(0.15)
    private let cardBackgroundActive = Color.white.opacity(0.25)
    private let accentBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    private let accentGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    private let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    private let accentPurple = Color(red: 0.6, green: 0.3, blue: 0.9)
    
    var body: some View {
        ZStack {
            // iOS 26 gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.12, blue: 0.25),
                    Color(red: 0.08, green: 0.08, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Status Bar
                    statusBar
                    
                    // Main Timer Card - Large prominent card
                    mainTimerCard
                    
                    // Quick Activity Grid
                    quickActivityGrid
                    
                    // Stats Row
                    statsRow
                    
                    // Recent Sessions
                    recentSessionsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingActivityPicker) {
            ActivityPickerView(selectedActivity: $selectedActivity, onStart: startActivity)
        }
    }
    
    // MARK: - Status Bar
    private var statusBar: some View {
        HStack {
            Text("Control Center")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Spacer()
            
            // Live indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(currentSession != nil ? accentGreen : Color.gray)
                    .frame(width: 8, height: 8)
                Text(currentSession != nil ? "Tracking" : "Idle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(cardBackground)
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Main Timer Card
    private var mainTimerCard: some View {
        VStack(spacing: 24) {
            // Activity Icon
            ZStack {
                Circle()
                    .fill(currentSession != nil ? accentBlue.opacity(0.3) : cardBackground)
                    .frame(width: 100, height: 100)
                
                Image(systemName: currentActivityType?.icon ?? "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(currentSession != nil ? accentBlue : .white)
                    .symbolEffect(.pulse, isActive: currentSession != nil)
            }
            
            // Timer Display
            VStack(spacing: 8) {
                Text(timerString)
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                
                Text(currentActivityType?.name ?? "Ready to Start")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            // Control Buttons
            HStack(spacing: 20) {
                if currentSession == nil {
                    // Start Button
                    ControlButton(
                        icon: "play.fill",
                        color: accentGreen,
                        size: 70
                    ) {
                        showingActivityPicker = true
                    }
                } else {
                    // Pause/Resume
                    ControlButton(
                        icon: "pause.fill",
                        color: accentOrange,
                        size: 60
                    ) {
                        togglePause()
                    }
                    
                    // Stop
                    ControlButton(
                        icon: "stop.fill",
                        color: Color.red.opacity(0.8),
                        size: 60
                    ) {
                        stopActivity()
                    }
                }
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(cardBackground)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Quick Activity Grid
    private var quickActivityGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(ActivityType.allCases.prefix(4)) { activity in
                QuickActivityButton(
                    activity: activity,
                    isActive: currentActivityType == activity,
                    action: { quickStart(activity) }
                )
            }
        }
    }
    
    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(sessions.count)",
                label: "Sessions",
                icon: "number",
                color: accentPurple
            )
            
            StatCard(
                value: formatDuration(totalDuration),
                label: "Total Time",
                icon: "clock",
                color: accentBlue
            )
            
            StatCard(
                value: "\(uniqueActivities)",
                label: "Activities",
                icon: "flame.fill",
                color: accentOrange
            )
        }
    }
    
    // MARK: - Recent Sessions Card
    private var recentSessionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Sessions")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                NavigationLink(destination: CalendarView()) {
                    Text("See All")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(accentBlue)
                }
            }
            
            if sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("No sessions yet")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 8) {
                    ForEach(sessions.prefix(3)) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBackground)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    private var timerString: String {
        guard let session = currentSession else { return "00:00:00" }
        let duration = session.duration
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private var currentActivityType: ActivityType? {
        currentSession?.activityTypeEnum
    }
    
    private var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    private var uniqueActivities: Int {
        Set(sessions.map { $0.activityType }).count
    }
    
    // MARK: - Actions
    private func quickStart(_ activity: ActivityType) {
        if currentSession == nil {
            selectedActivity = activity
            startActivity()
        }
    }
    
    private func startActivity() {
        guard let activity = selectedActivity else { return }
        let session = ActivitySession(activityType: activity, startTime: Date())
        modelContext.insert(session)
        currentSession = session
        selectedActivity = nil
    }
    
    private func stopActivity() {
        guard let session = currentSession else { return }
        session.endTime = Date()
        currentSession = nil
    }
    
    private func togglePause() {
        // Implement pause logic if needed
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        if hours > 0 {
            return "\(hours)h"
        }
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

// MARK: - Supporting Views

struct ControlButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: size, height: size)
                
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 1)
                    .frame(width: size, height: size)
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundStyle(color)
            }
        }
        .buttonStyle(.plain)
    }
}

struct QuickActivityButton: View {
    let activity: ActivityType
    let isActive: Bool
    let action: () -> Void
    
    private let cardBackground = Color.white.opacity(0.15)
    private let cardBackgroundActive = Color.white.opacity(0.3)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: activity.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isActive ? .white : activity.color)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isActive ? activity.color : cardBackground)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(isActive ? "In Progress" : "Tap to start")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? cardBackgroundActive : cardBackground)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? activity.color.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    private let cardBackground = Color.white.opacity(0.15)
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackground)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct SessionRow: View {
    let session: ActivitySession
    
    private var activityType: ActivityType {
        session.activityTypeEnum
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activityType.icon)
                .font(.system(size: 16))
                .foregroundStyle(activityType.color)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(activityType.color.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activityType.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                
                Text(session.startTime, style: .date)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text(formatDuration(session.duration))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%02dm", minutes)
    }
}

struct ActivityPickerView: View {
    @Binding var selectedActivity: ActivityType?
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Choose Activity") {
                    ForEach(ActivityType.allCases) { activity in
                        Button {
                            selectedActivity = activity
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onStart()
                            }
                        } label: {
                            HStack {
                                Image(systemName: activity.icon)
                                    .foregroundStyle(activity.color)
                                    .frame(width: 30)
                                
                                Text(activity.name)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if selectedActivity == activity {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Start Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ControlCenterView()
        .modelContainer(for: ActivitySession.self, inMemory: true)
}