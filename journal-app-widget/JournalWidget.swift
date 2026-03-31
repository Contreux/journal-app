// journal-app-widget/JournalWidget.swift

import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Color helper (duplicated from main app — no shared framework)

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Lock screen view

struct JournalLockScreenView: View {
    let context: ActivityViewContext<JournalActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: context.attributes.colorHex).opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: context.attributes.activityIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: context.attributes.colorHex))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(context.attributes.activityName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(formatElapsed(context.state.elapsedSeconds))
                    .font(.system(size: 26, weight: .light, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Widget

struct JournalLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: JournalActivityAttributes.self) { context in
            JournalLockScreenView(context: context)
                .background(.background)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: context.attributes.activityIcon)
                            .font(.title3)
                            .foregroundStyle(Color(hex: context.attributes.colorHex))
                        Text(context.attributes.activityName)
                            .font(.headline)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatElapsed(context.state.elapsedSeconds))
                        .font(.system(.title3, design: .rounded))
                        .monospacedDigit()
                        .padding(.trailing, 4)
                }
            } compactLeading: {
                Image(systemName: context.attributes.activityIcon)
                    .foregroundStyle(Color(hex: context.attributes.colorHex))
            } compactTrailing: {
                Text(formatElapsed(context.state.elapsedSeconds))
                    .font(.system(.caption, design: .rounded))
                    .monospacedDigit()
            } minimal: {
                Image(systemName: context.attributes.activityIcon)
                    .foregroundStyle(Color(hex: context.attributes.colorHex))
            }
        }
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

@main
struct JournalWidgetBundle: WidgetBundle {
    var body: some Widget {
        JournalLiveActivityWidget()
    }
}
