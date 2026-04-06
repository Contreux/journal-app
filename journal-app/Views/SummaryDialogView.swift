// journal-app/journal-app/Views/SummaryDialogView.swift

import SwiftUI

struct SummaryDialogView: View {
    let viewModel: ActivityTrackerViewModel
    let session: ActivitySession
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var summaryText = ""
    @State private var showingPermissionAlert = false
    @FocusState private var isTextFocused: Bool
    @State private var selectedDetent: PresentationDetent = .large
    
    private var isBusy: Bool {
        viewModel.isRecording
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(session.activityTypeEnum.color.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: session.activityTypeEnum.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(session.activityTypeEnum.color)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(session.activityTypeEnum.rawValue)
                            .font(.headline)
                        Text(session.formattedDuration)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Done") {
                        isTextFocused = false
                        if viewModel.isRecording { viewModel.stopRecording() }
                        onSave(summaryText)
                    }
                    .font(.body.weight(.semibold))
                    .disabled(isBusy)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider()

                // Scrollable text area — fills all available space
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ZStack(alignment: .topLeading) {
                            if summaryText.isEmpty {
                                Text("How did it go?")
                                    .foregroundStyle(.tertiary)
                                    .font(.body)
                                    .padding(.top, 2)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $summaryText)
                                .focused($isTextFocused)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 200)
                        }

                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    let granted = await viewModel.requestRecordingPermission()
                                    if granted {
                                        isTextFocused = false
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
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }

            }
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFocused = true
                }
            }
            .onDisappear { viewModel.resetAudioState() }
            .interactiveDismissDisabled(isBusy)
            .presentationDetents([.medium, .large], selection: $selectedDetent)
            .presentationDragIndicator(.visible)
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Skip") {
                        isTextFocused = false
                        if viewModel.isRecording { viewModel.stopRecording() }
                        onSave("")
                    }
                    .foregroundStyle(.secondary)
                    .disabled(isBusy)

                    Button("Done") {
                        isTextFocused = false
                        if viewModel.isRecording { viewModel.stopRecording() }
                        onSave(summaryText)
                    }
                    .fontWeight(.semibold)
                    .disabled(isBusy)
                }
            }
        }
    }
}

#Preview {
    SummaryDialogView(
        viewModel: ActivityTrackerViewModel(),
        session: ActivitySession(activityType: .gym),
        onSave: { _ in },
        onCancel: {}
    )
}
