// journal-app/journal-app/Views/ContentView.swift

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            ActivitiesView()
                .tabItem { Label("Track", systemImage: "plus.circle.fill") }

            CalendarView()
                .tabItem { Label("History", systemImage: "calendar") }
        }
    }
}

// MARK: - Active Session Card

struct ActiveSessionCard: View {
    let session: ActivitySession
    let elapsed: String
    let onTap: () -> Void
    let onStop: () -> Void
    let onNote: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(session.activityTypeEnum.color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: session.activityTypeEnum.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(session.activityTypeEnum.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.activityTypeEnum.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(elapsed)
                        .font(.system(size: 28, weight: .light, design: .rounded))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 60)
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .trailing) {
            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(session.activityTypeEnum.color, in: Circle())
            }
            .padding(.trailing, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(session.activityTypeEnum.color.opacity(0.08))
        )
    }
}

// MARK: - Active Session Edit Sheet

struct ActiveSessionEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: ActivitySession
    let viewModel: ActivityTrackerViewModel
    let onSave: () -> Void

    @State private var confirmingCancel = false
    @State private var showingPermissionAlert = false
    @FocusState private var isNotesFocused: Bool

    private var notesBinding: Binding<String> {
        Binding(
            get: { session.summary ?? "" },
            set: { session.summary = $0.isEmpty ? nil : $0 }
        )
    }
    
    private var isBusy: Bool {
        viewModel.isRecording
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(session.activityTypeEnum.color.opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: session.activityTypeEnum.icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(session.activityTypeEnum.color)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.activityTypeEnum.rawValue)
                                .font(.headline)
                            Text(viewModel.formattedDuration)
                                .font(.system(size: 32, weight: .light, design: .rounded))
                                .foregroundStyle(.primary)
                                .monospacedDigit()
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Start Time") {
                    DatePicker(
                        "Started",
                        selection: $session.startTime,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("Notes") {
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack(alignment: .topLeading) {
                            if notesBinding.wrappedValue.isEmpty {
                                Text("Add notes while you work…")
                                    .foregroundStyle(.tertiary)
                                    .font(.body)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: notesBinding)
                                .focused($isNotesFocused)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 160)
                                .padding(.vertical, 4)
                        }

                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    let granted = await viewModel.requestRecordingPermission()
                                    if granted {
                                        isNotesFocused = false
                                        viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
                                    } else {
                                        showingPermissionAlert = true
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    Text(viewModel.isRecording ? "Stop Recording" : "Voice Note")
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(viewModel.isRecording ? .red : .secondary)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            if viewModel.isRecording {
                                Text("Recording…")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    if confirmingCancel {
                        HStack(spacing: 12) {
                            Button("Keep Session") {
                                withAnimation { confirmingCancel = false }
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.bordered)

                            Button("Yes, Cancel", role: .destructive) {
                                viewModel.cancelSession(session, modelContext: modelContext)
                                dismiss()
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                        .padding(.vertical, 2)
                    } else {
                        Button(role: .destructive) {
                            withAnimation { confirmingCancel = true }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Cancel Session")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("In Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isNotesFocused = false
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(isBusy)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isNotesFocused = false }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onDisappear { viewModel.resetAudioState() }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Enable microphone access in Settings.")
        }
    }
}

// MARK: - Quick Start Chip

struct QuickStartChip: View {
    let name: String
    let icon: String
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(name)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(color.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environment(ActivityTrackerViewModel())
        .modelContainer(for: ActivitySession.self, inMemory: true)
}
