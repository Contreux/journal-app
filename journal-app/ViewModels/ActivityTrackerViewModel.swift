// journal-app/journal-app/ViewModels/ActivityTrackerViewModel.swift

import Foundation
import SwiftData
import AVFoundation
import Speech
import ActivityKit

@Observable
class ActivityTrackerViewModel {
    var currentSession: ActivitySession?
    var elapsedTime: TimeInterval = 0
    private var timer: Timer?

    // Confirmation flow
    var pendingActivity: ActivityType?

    // Live Activity
    private var liveActivity: Activity<JournalActivityAttributes>?

    // Audio recording
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    var isRecording = false
    var transcribedText = ""
    var isTranscribing = false
    var recordingError: String?

    // MARK: - Session Lifecycle

    func startActivity(_ type: ActivityType, modelContext: ModelContext) {
        if let session = currentSession {
            endSession(session, summary: nil, modelContext: modelContext)
        }
        let session = ActivitySession(activityType: type)
        modelContext.insert(session)
        currentSession = session
        startTimer()
        startLiveActivity(name: type.rawValue, icon: type.icon, colorHex: type.color.hexString)
        try? modelContext.save()
    }

    func confirmStart(modelContext: ModelContext) {
        guard let type = pendingActivity else { return }
        startActivity(type, modelContext: modelContext)
        pendingActivity = nil
    }

    func cancelStart() {
        pendingActivity = nil
    }

    func endSession(_ session: ActivitySession, summary: String?, modelContext: ModelContext) {
        stopTimer()
        endLiveActivity()
        session.endTime = Date()
        session.summary = summary
        if session.id == currentSession?.id {
            currentSession = nil
            elapsedTime = 0
        }
        try? modelContext.save()
    }

    func quickStop(modelContext: ModelContext) {
        if let session = currentSession {
            endSession(session, summary: nil, modelContext: modelContext)
        }
    }

    func stopCurrentSession(modelContext: ModelContext) {
        quickStop(modelContext: modelContext)
    }

    // MARK: - Timer

    var formattedDuration: String {
        let total = Int(elapsedTime)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let session = self.currentSession else { return }
            self.elapsedTime = Date().timeIntervalSince(session.startTime)
            // Update live activity every 30s to save battery
            if Int(self.elapsedTime) % 30 == 0 {
                self.updateLiveActivity(elapsed: Int(self.elapsedTime))
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Live Activity

    private func startLiveActivity(name: String, icon: String, colorHex: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = JournalActivityAttributes(activityName: name, activityIcon: icon, colorHex: colorHex)
        let state = JournalActivityAttributes.ContentState(elapsedSeconds: 0)
        let content = ActivityContent(state: state, staleDate: nil)
        do {
            liveActivity = try Activity.request(attributes: attributes, content: content)
        } catch {
            print("Live activity error: \(error)")
        }
    }

    private func updateLiveActivity(elapsed: Int) {
        guard let activity = liveActivity else { return }
        let state = JournalActivityAttributes.ContentState(elapsedSeconds: elapsed)
        let content = ActivityContent(state: state, staleDate: nil)
        Task { await activity.update(content) }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        liveActivity = nil
    }

    // MARK: - Audio

    func resetAudioState() {
        transcribedText = ""
        recordingError = nil
        isTranscribing = false
        isRecording = false
        audioRecorder?.stop()
        audioRecorder = nil
        recordingURL = nil
    }

    func requestRecordingPermission() async -> Bool {
        let mic = await withCheckedContinuation { c in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                c.resume(returning: granted)
            }
        }
        await withCheckedContinuation { c in
            SFSpeechRecognizer.requestAuthorization { _ in c.resume() }
        }
        return mic
    }

    func startRecording() {
        guard !isRecording else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("rec-\(UUID().uuidString).m4a")
            recordingURL = url

            audioRecorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            audioRecorder?.record()
            isRecording = true
            recordingError = nil
        } catch {
            recordingError = "Recording failed: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        if let url = recordingURL {
            transcribeAudio(url: url)
        }
    }

    private func transcribeAudio(url: URL) {
        isTranscribing = true
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            isTranscribing = false
            recordingError = "Speech recognition unavailable"
            return
        }
        recognizer.recognitionTask(with: SFSpeechURLRecognitionRequest(url: url)) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isTranscribing = false
                if let result = result, result.isFinal {
                    let text = result.bestTranscription.formattedString
                    if let existing = self?.transcribedText, !existing.isEmpty {
                        self?.transcribedText = existing + " " + text
                    } else {
                        self?.transcribedText = text
                    }
                } else if let error {
                    self?.recordingError = error.localizedDescription
                }
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    deinit {
        stopTimer()
        audioRecorder?.stop()
    }
}
