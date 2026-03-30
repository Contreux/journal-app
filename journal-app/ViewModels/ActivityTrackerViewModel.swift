// journal-app/journal-app/ViewModels/ActivityTrackerViewModel.swift
// ViewModel for tracking activities

import Foundation
import SwiftData
import AVFoundation
import Speech

@Observable
class ActivityTrackerViewModel {
    var currentSession: ActivitySession?
    var elapsedTime: TimeInterval = 0
    private var timer: Timer?
    
    // Audio recording properties
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    private var recordingURL: URL?
    
    var isRecording = false
    var transcribedText = ""
    var isTranscribing = false
    var recordingError: String?
    
    func startActivity(_ type: ActivityType, modelContext: ModelContext) {
        // End any existing session first
        if let session = currentSession {
            endSession(session, summary: nil, modelContext: modelContext)
        }
        
        let session = ActivitySession(activityType: type)
        modelContext.insert(session)
        currentSession = session
        
        startTimer()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save session: \(error)")
        }
    }
    
    func endSession(_ session: ActivitySession, summary: String?, modelContext: ModelContext) {
        stopTimer()
        
        session.endTime = Date()
        session.summary = summary
        
        if session.id == currentSession?.id {
            currentSession = nil
            elapsedTime = 0
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save session: \(error)")
        }
    }
    
    func stopCurrentSession(modelContext: ModelContext) {
        if let session = currentSession {
            endSession(session, summary: nil, modelContext: modelContext)
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateElapsedTime() {
        guard let session = currentSession else { return }
        elapsedTime = Date().timeIntervalSince(session.startTime)
    }
    
    // MARK: - Audio Recording
    
    func requestRecordingPermission() async -> Bool {
        // Request microphone permission
        let micStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        // Request speech recognition permission
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume()
            }
        }

        return micStatus
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording-\(UUID().uuidString).m4a")
            recordingURL = audioFilename
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            recordingError = nil
            
        } catch {
            recordingError = "Failed to start recording: \(error.localizedDescription)"
            print("Recording error: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        
        // Transcribe the recording
        if let url = recordingURL {
            transcribeAudio(url: url)
        }
    }
    
    private func transcribeAudio(url: URL) {
        isTranscribing = true
        
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            transcribedText = "Speech recognition not available"
            isTranscribing = false
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isTranscribing = false
                
                if let error = error {
                    self?.transcribedText = "Transcription error: \(error.localizedDescription)"
                    return
                }
                
                if let result = result, result.isFinal {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
                
                // Clean up the audio file
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    deinit {
        stopTimer()
        audioRecorder?.stop()
    }
}
