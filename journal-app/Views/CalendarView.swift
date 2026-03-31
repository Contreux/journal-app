// journal-app/journal-app/Views/CalendarView.swift

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivitySession.startTime, order: .reverse) private var allSessions: [ActivitySession]
    @Query(sort: \CustomActivityType.sortOrder) private var customTypes: [CustomActivityType]

    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var editingSession: ActivitySession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    CalendarGridView(
                        currentMonth: $currentMonth,
                        selectedDate: $selectedDate,
                        sessions: allSessions,
                        customTypes: customTypes
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    WeekSummaryStrip(selectedDate: selectedDate, sessions: allSessions)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                    Divider().padding(.horizontal, 16)

                    DaySessionsView(
                        date: selectedDate,
                        sessions: sessionsForDate(selectedDate),
                        customTypes: customTypes
                    ) { session in
                        editingSession = session
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("History")
            .sheet(item: $editingSession) { session in
                SessionEditView(session: session) {
                    modelContext.delete(session)
                }
            }
        }
    }

    private func sessionsForDate(_ date: Date) -> [ActivitySession] {
        allSessions.filter { Calendar.current.isDate($0.startTime, inSameDayAs: date) }
    }
}

// MARK: - Calendar Grid

struct CalendarGridView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let sessions: [ActivitySession]
    var customTypes: [CustomActivityType] = []

    private let calendar = Calendar.current
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    private let monthFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
    }()

    var body: some View {
        VStack(spacing: 12) {
            // Month header
            HStack {
                Text(monthFormatter.string(from: currentMonth))
                    .font(.title3.bold())
                Spacer()
                HStack(spacing: 16) {
                    Button { step(-1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                    }
                    Button { step(1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .padding(.top, 8)

            // Weekday labels
            HStack(spacing: 0) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            sessionColors: sessionColors(on: date)
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25)) { selectedDate = date }
                        }
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }

    private func step(_ months: Int) {
        withAnimation(.spring(response: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: months, to: currentMonth)!
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        let offset = calendar.component(.weekday, from: interval.start) - 1
        var dates: [Date?] = Array(repeating: nil, count: offset)
        var d = interval.start
        while d < interval.end {
            dates.append(d)
            d = calendar.date(byAdding: .day, value: 1, to: d)!
        }
        return dates
    }

    private func sessionColors(on date: Date) -> [Color] {
        let daySessions = sessions
            .filter { calendar.isDate($0.startTime, inSameDayAs: date) }
            .sorted { $0.duration > $1.duration }
        return Array(daySessions.prefix(3).map { $0.resolvedType(customTypes: customTypes).color })
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let sessionColors: [Color]

    private let calendar = Calendar.current
    private let accent = Color(red: 0.95, green: 0.55, blue: 0.25)

    var body: some View {
        VStack(spacing: 3) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 15, weight: isToday ? .bold : .regular))
                .foregroundStyle(.primary)
                .frame(width: 34, height: 34)
                .background(isSelected ? accent.opacity(0.15) : Color.clear, in: Circle())
                .overlay(isToday ? Circle().stroke(accent, lineWidth: 2) : nil)

            if !sessionColors.isEmpty {
                HStack(spacing: 3) {
                    ForEach(Array(sessionColors.enumerated()), id: \.offset) { _, color in
                        Circle().fill(color).frame(width: 5, height: 5)
                    }
                }
            } else {
                Color.clear.frame(height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
}

// MARK: - Week Summary Strip

struct WeekSummaryStrip: View {
    let selectedDate: Date
    let sessions: [ActivitySession]

    private let calendar = Calendar.current

    private var weekSessions: [ActivitySession] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return sessions.filter { $0.startTime >= weekInterval.start && $0.startTime < weekInterval.end }
    }

    private var weekTotal: TimeInterval {
        weekSessions.reduce(0) { $0 + $1.duration }
    }

    private struct CategorySlice: Identifiable {
        let id = UUID()
        let color: Color
        let fraction: CGFloat
    }

    private var slices: [CategorySlice] {
        guard weekTotal > 0 else { return [] }
        let catColors: [ActivityCategory: Color] = [
            .body: Color(red: 0.90, green: 0.30, blue: 0.30),
            .mind: Color(red: 0.40, green: 0.40, blue: 0.70),
            .life: Color(red: 0.40, green: 0.72, blue: 0.72),
        ]
        var totals: [ActivityCategory: TimeInterval] = [:]
        for s in weekSessions {
            totals[s.activityTypeEnum.category, default: 0] += s.duration
        }
        return totals.compactMap { cat, dur in
            CategorySlice(color: catColors[cat] ?? .gray, fraction: CGFloat(dur / weekTotal))
        }.sorted { $0.fraction > $1.fraction }
    }

    var body: some View {
        if !weekSessions.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Week total: \(formatDuration(weekTotal))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(slices) { slice in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(slice.color)
                                .frame(width: max(4, (geo.size.width - CGFloat(slices.count - 1) * 2) * slice.fraction))
                        }
                    }
                }
                .frame(height: 4)
            }
            .padding(.vertical, 8)
        }
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600, m = (Int(t) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Day Sessions View

struct DaySessionsView: View {
    let date: Date
    let sessions: [ActivitySession]
    var customTypes: [CustomActivityType] = []
    let onTap: (ActivitySession) -> Void

    private var dateLabel: String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"; return f.string(from: date)
    }

    private var dayTotal: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dateLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !sessions.isEmpty {
                    Text(formatDuration(dayTotal))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            if sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.quaternary)
                    Text("Nothing tracked")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(sessions) { session in
                    SessionRow(session: session, customTypes: customTypes)
                        .onTapGesture { onTap(session) }
                }
            }
        }
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600, m = (Int(t) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: ActivitySession
    var customTypes: [CustomActivityType] = []

    var body: some View {
        let resolved = session.resolvedType(customTypes: customTypes)
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(resolved.color)
                .frame(width: 3)
                .padding(.vertical, 4)

            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(resolved.color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: resolved.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(resolved.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(resolved.name)
                        .font(.subheadline.weight(.semibold))
                    if let summary = session.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(session.formattedTimeRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(session.compactDuration)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(resolved.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Session Edit View

struct SessionEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ActivityTrackerViewModel.self) private var viewModel
    @Bindable var session: ActivitySession
    let onDelete: () -> Void

    @Query(sort: \CustomActivityType.sortOrder) private var customTypes: [CustomActivityType]
    @State private var confirmingCancel = false
    @State private var confirmingDelete = false
    @State private var showingTypePicker = false
    @FocusState private var isNotesFocused: Bool

    private var notesBinding: Binding<String> {
        Binding(
            get: { session.summary ?? "" },
            set: { session.summary = $0.isEmpty ? nil : $0 }
        )
    }

    private var resolved: (name: String, icon: String, color: Color) {
        session.resolvedType(customTypes: customTypes)
    }

    var body: some View {
        NavigationStack {
            List {
                // Activity header — tappable to change type
                Section {
                    Button {
                        showingTypePicker = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(resolved.color.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                Image(systemName: resolved.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(resolved.color)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(resolved.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(session.compactDuration)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Times
                Section("Time") {
                    DatePicker("Start", selection: $session.startTime, displayedComponents: [.date, .hourAndMinute])
                    if session.endTime != nil {
                        DatePicker("End", selection: Binding(
                            get: { session.endTime ?? Date() },
                            set: { session.endTime = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    } else {
                        Button {
                            session.endTime = Date()
                        } label: {
                            Label("Add End Time", systemImage: "plus.circle")
                        }
                    }
                }

                // Notes — full-height TextEditor inside the List
                Section("Notes") {
                    ZStack(alignment: .topLeading) {
                        if notesBinding.wrappedValue.isEmpty {
                            Text("Add notes…")
                                .foregroundStyle(.tertiary)
                                .font(.body)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: notesBinding)
                            .focused($isNotesFocused)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 120)
                            .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                // Cancel active session / delete completed session
                Section {
                    if session.isActive {
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
                                withAnimation {
                                    confirmingDelete = false
                                    confirmingCancel = true
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Cancel Session")
                                    Spacer()
                                }
                            }
                        }
                    } else if confirmingDelete {
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                withAnimation { confirmingDelete = false }
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.bordered)

                            Button("Yes, Delete", role: .destructive) {
                                onDelete()
                                dismiss()
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                        .padding(.vertical, 2)
                    } else {
                        Button(role: .destructive) {
                            withAnimation { confirmingDelete = true }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Session")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isNotesFocused = false
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isNotesFocused = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingTypePicker) {
            SessionTypePickerView(customTypes: customTypes) { name in
                session.activityType = name
                showingTypePicker = false
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Session Type Picker

struct SessionTypePickerView: View {
    let customTypes: [CustomActivityType]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(ActivityType.grouped, id: \.category) { group in
                    let catCustom = customTypes.filter { $0.category == group.category }
                    Section(group.category.rawValue) {
                        ForEach(group.types) { type in
                            typeRow(name: type.rawValue, icon: type.icon, color: type.color)
                        }
                        ForEach(catCustom) { custom in
                            typeRow(name: custom.name, icon: custom.symbol, color: custom.color)
                        }
                    }
                }
            }
            .navigationTitle("Change Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func typeRow(name: String, icon: String, color: Color) -> some View {
        Button {
            onSelect(name)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(name)
                    .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: ActivitySession.self, inMemory: true)
}
