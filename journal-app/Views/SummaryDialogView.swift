// journal-app/journal-app/Views/SummaryDialogView.swift
// Dialog for recording or typing activity summary

import SwiftUI

struct SummaryDialogView: View {
    let viewModel: ActivityTrackerViewModel
    let session: ActivitySession
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    @State private var summaryText = ""
    @State private var showingPermissionAlert = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: session.activityTypeEnum.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(session.activityTypeEnum.color)
                    
                    Text(session.activityTypeEnum.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Duration: \(session.formattedDuration)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // Recording Section
                VStack(spacing: 16) {
                    Text("Record a summary")
                        .font(.headline)
                    
                    // Record Button
                    Button {
                        Task {
                            let granted = await viewModel.requestRecordingPermission()
                            if granted {
                                if viewModel.isRecording {
                                    viewModel.stopRecording()
                                } else {
                                    viewModel.startRecording()
                                }
                            } else {
                                showingPermissionAlert = true
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(viewModel.isRecording ? Color.red : session.activityTypeEnum.color)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                    }
                    
                    Text(viewModel.isRecording ? "Tap to stop recording" : "Tap to start recording")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if viewModel.isTranscribing {
                        ProgressView("Transcribing...")
                            .padding(.top, 8)
                    }
                    
                    if let error = viewModel.recordingError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Transcribed/Editable Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.headline)
                    
                    TextEditor(text: $summaryText)
                        .frame(minHeight: 100, maxHeight: 150)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.separator, lineWidth: 1)
                        )
                        .focused($isTextFieldFocused)
                        .onChange(of: viewModel.transcribedText) { oldValue, newValue in
                            if !newValue.isEmpty {
                                summaryText = newValue
                            }
                        }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        }
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Save") {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        }
                        onSave(summaryText)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isTranscribing)
                }
            }
            .padding()
            .navigationBarHidden(true)
            .alert("Permission Required", isPresented: $showingPermissionAlert) {
                Button("OK", role: .cancel) {}
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable microphone and speech recognition permissions in Settings to use voice recording.")
            }
        }
    }
}

#Preview {
    let session = ActivitySession(activityType: .gym)
    SummaryDialogView(
        viewModel: ActivityTrackerViewModel(),
        session: session,
        onSave: { _ in },
        onCancel: {}
    )
}
