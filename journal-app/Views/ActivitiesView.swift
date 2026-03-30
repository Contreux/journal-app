// journal-app/journal-app/Views/ActivitiesView.swift

import SwiftUI
import SwiftData

struct ActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ActivityTrackerViewModel.self) private var viewModel
    @State private var showingSummaryDialog = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Active session banner
                        if let session = viewModel.currentSession {
                            ActiveSessionCard(
                                session: session,
                                elapsed: viewModel.formattedDuration,
                                onStop: { viewModel.quickStop(modelContext: modelContext) },
                                onNote: { showingSummaryDialog = true }
                            )
                        }

                        // Grouped activity grid
                        ForEach(ActivityType.grouped, id: \.category) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.category.rawValue.uppercased())
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)

                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(group.types) { type in
                                        ActivityTile(
                                            type: type,
                                            isActive: viewModel.currentSession?.activityTypeEnum == type,
                                            isPressed: false
                                        )
                                        .onTapGesture {
                                            viewModel.pendingActivity = type
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
                .navigationTitle("Track")

                // Confirmation overlay
                if let type = viewModel.pendingActivity {
                    ConfirmationOverlay(
                        type: type,
                        onStart: { viewModel.confirmStart(modelContext: modelContext) },
                        onCancel: { viewModel.cancelStart() }
                    )
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
                        onCancel: { showingSummaryDialog = false }
                    )
                }
            }
        }
    }
}

// MARK: - Activity Tile

struct ActivityTile: View {
    let type: ActivityType
    let isActive: Bool
    let isPressed: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(type.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: type.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(type.color)
                    )

                if isActive {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }

            Text(type.rawValue)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            isActive ?
                RoundedRectangle(cornerRadius: 14)
                    .stroke(type.color.opacity(0.4), lineWidth: 1.5)
                : nil
        )
        .scaleEffect(isPressed ? 0.92 : 1.0)
    }
}

// MARK: - Confirmation Overlay

struct ConfirmationOverlay: View {
    let type: ActivityType
    let onStart: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { onCancel() } }

            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 20) {
                    Circle()
                        .fill(type.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: type.icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(type.color)
                        )

                    Text("Start tracking \(type.rawValue)?")
                        .font(.headline)

                    HStack(spacing: 12) {
                        Button("Cancel") {
                            withAnimation { onCancel() }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        Button("Start") {
                            withAnimation { onStart() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(type.color)
                        .controlSize(.large)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: type)
    }
}

#Preview {
    ActivitiesView()
        .environment(ActivityTrackerViewModel())
        .modelContainer(for: ActivitySession.self, inMemory: true)
}
