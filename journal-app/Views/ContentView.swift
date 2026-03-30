// journal-app/journal-app/Views/ContentView.swift

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.horizon.fill") }
                .tag(0)

            ActivitiesView()
                .tabItem { Label("Track", systemImage: "plus.circle.fill") }
                .tag(1)

            CalendarView()
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(2)
        }
    }
}

// MARK: - Today Tab

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ActivityTrackerViewModel.self) private var viewModel
    @Query(sort: \ActivitySession.startTime, order: .reverse) private var allSessions: [ActivitySession]
    @State private var editingSession: ActivitySession?
    @State private var showingSummaryDialog = false

    private var todaySessions: [ActivitySession] {
        allSessions.filter { Calendar.current.isDateInToday($0.startTime) && !$0.isActive }
    }

    private var todayTotal: TimeInterval {
        todaySessions.reduce(0) { $0 + $1.duration }
    }

    private var recentTypes: [ActivityType] {
        var seen = Set<String>()
        var result: [ActivityType] = []
        for session in allSessions {
            if seen.insert(session.activityType).inserted {
                result.append(session.activityTypeEnum)
            }
            if result.count >= 5 { break }
        }
        if result.isEmpty {
            return Array(ActivityType.allCases.prefix(5))
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Active session
                    if let session = viewModel.currentSession {
                        ActiveSessionCard(
                            session: session,
                            elapsed: viewModel.formattedDuration,
                            onStop: { viewModel.quickStop(modelContext: modelContext) },
                            onNote: { showingSummaryDialog = true }
                        )
                    }

                    // Today's completed sessions
                    if !todaySessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("What you did")
                                    .font(.title3.weight(.semibold))
                                Spacer()
                                Text(formatTotal(todayTotal))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(todaySessions) { session in
                                SessionPill(session: session)
                                    .onTapGesture { editingSession = session }
                            }
                        }
                    }

                    // Empty state
                    if viewModel.currentSession == nil && todaySessions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.quaternary)
                            Text("Your day is a blank page")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Text("Start tracking from the Track tab")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    }

                    // Quick start
                    VStack(alignment: .leading, spacing: 10) {
                        Text("QUICK START")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(recentTypes) { type in
                                    QuickStartChip(type: type) {
                                        viewModel.startActivity(type, modelContext: modelContext)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .navigationTitle("Today")
            .sheet(isPresented: $showingSummaryDialog) {
                if let session = viewModel.currentSession {
                    SummaryDialogView(
                        viewModel: viewModel,
                        session: session,
                        onSave: { summary in
                            viewModel.endSession(session, summary: summary, modelContext: modelContext)
                            showingSummaryDialog = false
                        },
                        onCancel: { showingSummaryDialog = false }
                    )
                }
            }
            .sheet(item: $editingSession) { session in
                SessionEditView(session: session) {
                    modelContext.delete(session)
                }
            }
        }
    }

    private func formatTotal(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m total" }
        return "\(m)m total"
    }
}

// MARK: - Active Session Card

struct ActiveSessionCard: View {
    let session: ActivitySession
    let elapsed: String
    let onStop: () -> Void
    let onNote: () -> Void

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(session.activityTypeEnum.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                    .scaleEffect(pulse ? 1.06 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                Image(systemName: session.activityTypeEnum.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(session.activityTypeEnum.color)
            }
            .onAppear { pulse = true }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.activityTypeEnum.rawValue)
                    .font(.headline)
                Text(elapsed)
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }

            Spacer()

            VStack(spacing: 6) {
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(session.activityTypeEnum.color, in: Circle())
                }

                Button("Note", action: onNote)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(session.activityTypeEnum.color.opacity(0.08))
        )
    }
}

// MARK: - Session Pill (Today list)

struct SessionPill: View {
    let session: ActivitySession

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(session.activityTypeEnum.color)
                .frame(width: 3)
                .padding(.vertical, 4)

            HStack(spacing: 10) {
                Image(systemName: session.activityTypeEnum.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(session.activityTypeEnum.color)
                    .frame(width: 20)

                Text(session.activityTypeEnum.rawValue)
                    .font(.subheadline.weight(.medium))

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(session.compactDuration)
                        .font(.caption.weight(.semibold))
                    Text(session.formattedTimeRange)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Quick Start Chip

struct QuickStartChip: View {
    let type: ActivityType
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 13))
                Text(type.rawValue)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(type.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(type.color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environment(ActivityTrackerViewModel())
        .modelContainer(for: ActivitySession.self, inMemory: true)
}
