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
                    .disabled(viewModel.isTranscribing)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider()

                // Scrollable text area — fills all available space
                ScrollView {
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
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    // Voice recording
                                    Button {
                                        Task {
                                            let granted = await viewModel.requestRecordingPermission()
                                            if granted {
                                                viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
                                            } else {
                                                showingPermissionAlert = true
                                            }
                                        }
                                    } label: {
                                        if viewModel.isTranscribing {
                                            ProgressView().scaleEffect(0.8)
                                        } else {
                                            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle")
                                                .font(.system(size: 22))
                                                .foregroundStyle(viewModel.isRecording ? .red : .secondary)
                                        }
                                    }

                                    if viewModel.isRecording {
                                        Text("Recording…")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    } else if viewModel.isTranscribing {
                                        Text("Transcribing…")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button("Skip") {
                                        isTextFocused = false
                                        if viewModel.isRecording { viewModel.stopRecording() }
                                        onSave("")
                                    }
                                    .foregroundStyle(.secondary)

                                    Button("Done") {
                                        isTextFocused = false
                                        if viewModel.isRecording { viewModel.stopRecording() }
                                        onSave(summaryText)
                                    }
                                    .fontWeight(.semibold)
                                    .disabled(viewModel.isTranscribing)
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }

                // Recording error (outside keyboard)
                if let error = viewModel.recordingError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 20)
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
            .onChange(of: viewModel.transcribedText) { _, newValue in
                guard !newValue.isEmpty else { return }
                summaryText = summaryText.isEmpty ? newValue : summaryText + " " + newValue
            }
            .interactiveDismissDisabled(viewModel.isRecording)
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
                Text("Enable microphone and speech recognition in Settings.")
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
