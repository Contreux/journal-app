// journal-app/journal-app/ViewModels/ActivityTrackerViewModel.swift

import Foundation
import SwiftData
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

    // MARK: - Session Lifecycle

    func startActivity(_ type: ActivityType, modelContext: ModelContext) {
        if let session = currentSession {
            endSession(session, summary: nil, modelContext: modelContext)
        }
        let session = ActivitySession(activityType: type)
        modelContext.insert(session)
        currentSession = session
        startTimer()
        startLiveActivity(name: type.rawValue, icon: type.icon, colorHex: type.color.hexString, startTime: session.startTime)
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
        endLiveActivity(startTime: session.startTime)
        session.endTime = Date()
        session.summary = summary
        if session.id == currentSession?.id {
            currentSession = nil
            elapsedTime = 0
        }
        try? modelContext.save()
    }

    func resumeSession(_ session: ActivitySession, modelContext: ModelContext) {
        if let existing = currentSession, existing.id != session.id {
            endSession(existing, summary: nil, modelContext: modelContext)
        } else if let existing = currentSession {
            stopTimer()
            endLiveActivity(startTime: existing.startTime)
        }

        session.endTime = nil
        currentSession = session
        elapsedTime = Date().timeIntervalSince(session.startTime)
        startTimer()

        if let type = ActivityType(rawValue: session.activityType) {
            startLiveActivity(name: type.rawValue, icon: type.icon, colorHex: type.color.hexString, startTime: session.startTime)
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

    func cancelSession(_ session: ActivitySession, modelContext: ModelContext) {
        if session.id == currentSession?.id {
            stopTimer()
            endLiveActivity(startTime: session.startTime)
            currentSession = nil
            elapsedTime = 0
        }
        modelContext.delete(session)
        try? modelContext.save()
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
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Live Activity

    func syncCurrentSessionLiveActivity() {
        guard let session = currentSession else { return }
        updateLiveActivity(startTime: session.startTime)
    }

    private func startLiveActivity(name: String, icon: String, colorHex: String, startTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = JournalActivityAttributes(activityName: name, activityIcon: icon, colorHex: colorHex)
        let state = JournalActivityAttributes.ContentState(startTime: startTime)
        let content = ActivityContent(state: state, staleDate: nil)
        do {
            liveActivity = try Activity.request(attributes: attributes, content: content)
        } catch {
            print("Live activity error: \(error)")
        }
    }

    private func updateLiveActivity(startTime: Date) {
        guard let activity = liveActivity else { return }
        let state = JournalActivityAttributes.ContentState(startTime: startTime)
        let content = ActivityContent(state: state, staleDate: nil)
        Task { await activity.update(content) }
    }

    private func endLiveActivity(startTime: Date) {
        guard let activity = liveActivity else { return }
        Task {
            let content = ActivityContent(
                state: JournalActivityAttributes.ContentState(startTime: startTime),
                staleDate: Date()
            )
            await activity.end(content, dismissalPolicy: .immediate)
        }
        liveActivity = nil
    }

    deinit {
        stopTimer()
    }
}
