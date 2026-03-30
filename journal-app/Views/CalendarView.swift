// journal-app/journal-app/Views/CalendarView.swift
// Monthly calendar with day detail view

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivitySession.startTime, order: .reverse) private var allSessions: [ActivitySession]
    
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month Header
                MonthHeaderView(currentMonth: $currentMonth)
                
                // Calendar Grid
                CalendarGridView(currentMonth: currentMonth, selectedDate: $selectedDate, sessions: allSessions)
                    .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Selected Date Sessions
                DayDetailView(date: selectedDate, sessions: sessionsForDate(selectedDate))
            }
            .navigationTitle("Activity History")
        }
    }
    
    private func sessionsForDate(_ date: Date) -> [ActivitySession] {
        let calendar = Calendar.current
        return allSessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: date)
        }
    }
}

struct MonthHeaderView: View {
    @Binding var currentMonth: Date
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        HStack {
            Button {
                withAnimation {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            Text(monthFormatter.string(from: currentMonth))
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button {
                withAnimation {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
    }
}

struct CalendarGridView: View {
    let currentMonth: Date
    @Binding var selectedDate: Date
    let sessions: [ActivitySession]
    
    private let calendar = Calendar.current
    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasSessions: hasSessions(on: date)
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var dates: [Date?] = []
        var current = firstWeek.start
        
        // Fill leading empty days
        let weekdayOffset = calendar.component(.weekday, from: monthInterval.start) - 1
        dates.append(contentsOf: Array(repeating: nil, count: weekdayOffset))
        
        // Fill days of month
        while current < monthInterval.end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        return dates
    }
    
    private func hasSessions(on date: Date) -> Bool {
        sessions.contains { session in
            calendar.isDate(session.startTime, inSameDayAs: date)
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasSessions: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        Text("\(calendar.component(.day, from: date))")
            .font(.body)
            .fontWeight(isToday ? .bold : .regular)
            .foregroundStyle(isToday ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                Circle()
                    .fill(backgroundColor)
            )
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .overlay(
                // Activity indicator dot
                hasSessions ?
                Circle()
                    .fill(isToday ? .white : .blue)
                    .frame(width: 6, height: 6)
                    .offset(y: 12)
                : nil
            )
    }
    
    private var backgroundColor: Color {
        if isToday {
            return .blue
        } else if isSelected {
            return .blue.opacity(0.2)
        } else {
            return .clear
        }
    }
}

struct DayDetailView: View {
    let date: Date
    let sessions: [ActivitySession]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dateFormatter.string(from: date))
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Activities",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("No activities recorded for this day")
                )
            } else {
                List {
                    ForEach(sessions) { session in
                        SessionRow(session: session)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct SessionRow: View {
    let session: ActivitySession

    private var activityType: ActivityType {
        session.activityTypeEnum
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activityType.icon)
                .font(.system(size: 16))
                .foregroundStyle(activityType.color)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(activityType.color.opacity(0.2))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(activityType.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)

                Text(session.startTime, style: .date)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formatDuration(session.duration))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%02dm", minutes)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: ActivitySession.self, inMemory: true)
}
