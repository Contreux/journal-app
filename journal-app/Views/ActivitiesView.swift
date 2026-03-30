// journal-app/journal-app/Views/ActivitiesView.swift
// Clean iOS 26 activity tracking with liquid glass design

import SwiftUI
import SwiftData

struct ActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ActivityTrackerViewModel.self) private var viewModel
    @State private var showingSummaryDialog = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(ActivityType.allCases) { activityType in
                                    ActivityCard(type: activityType) {
                                        viewModel.startActivity(activityType, modelContext: modelContext)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .safeAreaInset(edge: .bottom) {
                if viewModel.currentSession != nil {
                    ActiveSessionBar(viewModel: viewModel) {
                        showingSummaryDialog = true
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showingSummaryDialog) {
                if let session = viewModel.currentSession {
                    SummaryDialogView(
                        viewModel: viewModel,
                        session: session,
                        onSave: { summary in
                            viewModel.endSession(session, summary: summary, modelContext: modelContext)
                            showingSummaryDialog = false
                        },
                        onCancel: {
                            showingSummaryDialog = false
                        }
                    )
                }
            }
        }
    }
}

struct ActivityCard: View {
    let type: ActivityType
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: type.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(type.color)
                }

                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ActiveSessionBar: View {
    let viewModel: ActivityTrackerViewModel
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                (viewModel.currentSession?.activityTypeEnum.color ?? .blue)
                                    .opacity(0.2)
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: viewModel.currentSession?.activityTypeEnum.icon ?? "circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(viewModel.currentSession?.activityTypeEnum.color ?? .blue)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.currentSession?.activityTypeEnum.rawValue ?? "Unknown")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Tap to finish")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Timer
                    Text(viewModel.formattedDuration)
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
            .buttonStyle(.plain)
            .padding(12)
        }
    }
}

extension ActivityTrackerViewModel {
    var formattedDuration: String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    ActivitiesView()
        .environment(ActivityTrackerViewModel())
        .modelContainer(for: ActivitySession.self, inMemory: true)
}
