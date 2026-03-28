// journal-app/journal-app/Views/ActivitiesView.swift
// Grid of activity types with active session bar

import SwiftUI
import SwiftData

struct ActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ActivityTrackerViewModel()
    @State private var showingSummaryDialog = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Activity Grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(ActivityType.allCases) { activityType in
                                ActivityCard(type: activityType) {
                                    viewModel.startActivity(activityType, modelContext: modelContext)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Active Session Bar (if any)
                    if viewModel.currentSession != nil {
                        ActiveSessionBar(viewModel: viewModel) {
                            showingSummaryDialog = true
                        }
                        .transition(.move(edge: .bottom))
                    }
                }
            }
            .navigationTitle("What are you doing?")
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
                            // Just close, keep session running
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
                Image(systemName: type.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(type.color)
                
                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(type.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(type.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ActiveSessionBar: View {
    let viewModel: ActivityTrackerViewModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Activity Icon
                Image(systemName: viewModel.currentSession?.activityTypeEnum.icon ?? "circle")
                    .font(.title2)
                    .foregroundStyle(viewModel.currentSession?.activityTypeEnum.color ?? .blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill((viewModel.currentSession?.activityTypeEnum.color ?? .blue).opacity(0.2))
                    )
                
                // Activity Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.currentSession?.activityTypeEnum.rawValue ?? "Unknown")
                        .font(.headline)
                    
                    Text("Tap to add summary")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Timer
                Text(viewModel.formattedDuration)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.separator)
                    .frame(maxHeight: .infinity, alignment: .top)
            )
        }
        .buttonStyle(.plain)
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
        .modelContainer(for: ActivitySession.self, inMemory: true)
}
