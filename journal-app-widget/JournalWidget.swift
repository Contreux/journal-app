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

private struct ElapsedTimerText: View {
    let startTime: Date
    let font: Font

    var body: some View {
        Text(startTime, style: .timer)
            .font(font)
            .monospacedDigit()
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
                ElapsedTimerText(
                    startTime: context.state.startTime,
                    font: .system(size: 26, weight: .light, design: .rounded)
                )
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
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
                    ElapsedTimerText(
                        startTime: context.state.startTime,
                        font: .system(.title3, design: .rounded)
                    )
                        .padding(.trailing, 4)
                }
            } compactLeading: {
                Image(systemName: context.attributes.activityIcon)
                    .foregroundStyle(Color(hex: context.attributes.colorHex))
            } compactTrailing: {
                ElapsedTimerText(
                    startTime: context.state.startTime,
                    font: .system(.caption, design: .rounded)
                )
                .frame(width: 38, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            } minimal: {
                Image(systemName: context.attributes.activityIcon)
                    .foregroundStyle(Color(hex: context.attributes.colorHex))
            }
        }
    }
}

@main
struct JournalWidgetBundle: WidgetBundle {
    var body: some Widget {
        JournalLiveActivityWidget()
    }
}
