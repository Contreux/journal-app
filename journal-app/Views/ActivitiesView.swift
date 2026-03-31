// journal-app/journal-app/Views/ActivitiesView.swift

import SwiftUI
import SwiftData

struct ActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ActivityTrackerViewModel.self) private var viewModel

    @Query(filter: #Predicate<ActivitySession> { $0.endTime == nil },
           sort: \ActivitySession.startTime, order: .forward)
    private var activeSessions: [ActivitySession]

    @Query(sort: \ActivitySession.startTime, order: .reverse)
    private var allSessions: [ActivitySession]

    @Query(sort: \CustomActivityType.sortOrder)
    private var customTypes: [CustomActivityType]

    @State private var showingSummaryDialog = false
    @State private var editingSession: ActivitySession?
    @State private var addingToCategory: ActivityCategory?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    private var recentTypes: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for session in allSessions {
            if seen.insert(session.activityType).inserted {
                result.append(session.activityType)
            }
            if result.count >= 6 { break }
        }
        if result.isEmpty {
            return Array(ActivityType.allCases.prefix(6).map { $0.rawValue })
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Quick start (only when nothing is running)
                        if activeSessions.isEmpty && !recentTypes.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("RECENT")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(recentTypes, id: \.self) { typeName in
                                            let resolved = resolveType(typeName)
                                            QuickStartChip(
                                                name: resolved.name,
                                                icon: resolved.icon,
                                                color: resolved.color
                                            ) {
                                                startActivity(name: typeName)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // All running sessions
                        if !activeSessions.isEmpty {
                            VStack(spacing: 10) {
                                ForEach(activeSessions) { session in
                                    let isLive = session.id == viewModel.currentSession?.id
                                    ActiveSessionCard(
                                        session: session,
                                        elapsed: isLive ? viewModel.formattedDuration : session.compactDuration,
                                        onTap: { editingSession = session },
                                        onStop: {
                                            if isLive {
                                                viewModel.endSession(session, summary: nil, modelContext: modelContext)
                                            } else {
                                                session.endTime = Date()
                                                try? modelContext.save()
                                            }
                                            editingSession = session
                                        },
                                        onNote: { editingSession = session }
                                    )
                                }
                            }
                        }

                        // Grouped activity grid
                        ForEach(ActivityType.grouped, id: \.category) { group in
                            let catCustom = customTypes.filter { $0.category == group.category }
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.category.rawValue.uppercased())
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)

                                LazyVGrid(columns: columns, spacing: 12) {
                                    // Built-in tiles
                                    ForEach(group.types) { type in
                                        ActivityTile(
                                            name: type.rawValue,
                                            icon: type.icon,
                                            color: type.color,
                                            isActive: activeSessions.contains { $0.activityType == type.rawValue }
                                        )
                                        .onTapGesture {
                                            viewModel.startActivity(type, modelContext: modelContext)
                                        }
                                    }

                                    // Custom tiles for this category
                                    ForEach(catCustom) { custom in
                                        ActivityTile(
                                            name: custom.name,
                                            icon: custom.symbol,
                                            color: custom.color,
                                            isActive: activeSessions.contains { $0.activityType == custom.name }
                                        )
                                        .onTapGesture {
                                            startCustomActivity(custom)
                                        }
                                        .contextMenu {
                                            // Move to other categories
                                            ForEach(ActivityCategory.allCases.filter { $0 != custom.category }) { cat in
                                                Button {
                                                    custom.categoryName = cat.rawValue
                                                    try? modelContext.save()
                                                } label: {
                                                    Label("Move to \(cat.rawValue)", systemImage: cat.icon)
                                                }
                                            }
                                            Divider()
                                            Button(role: .destructive) {
                                                modelContext.delete(custom)
                                                try? modelContext.save()
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }

                                    // Add button
                                    Button {
                                        addingToCategory = group.category
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundStyle(.secondary)
                                                .frame(width: 44, height: 44)
                                                .background(Circle().fill(Color(.tertiarySystemFill)))
                                            Text("Add")
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(Color(.tertiarySystemFill))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .navigationTitle("Track")
            }
            .sheet(item: $addingToCategory) { category in
                NewActivityTypeSheet(defaultCategory: category) { name, symbol, colorHex, catName in
                    let order = customTypes.count
                    let custom = CustomActivityType(name: name, symbol: symbol, colorHex: colorHex, categoryName: catName, sortOrder: order)
                    modelContext.insert(custom)
                    try? modelContext.save()
                }
            }
            .sheet(item: $editingSession) { session in
                if session.endTime == nil, session.id == viewModel.currentSession?.id {
                    ActiveSessionEditView(session: session, viewModel: viewModel) {
                        try? modelContext.save()
                    }
                } else {
                    SessionEditView(session: session) {
                        modelContext.delete(session)
                    }
                }
            }
            .sheet(isPresented: $showingSummaryDialog) {
                if let session = viewModel.currentSession {
                    SummaryDialogView(
                        viewModel: viewModel,
                        session: session,
                        onSave: { summary in
                            viewModel.endSession(session, summary: summary, modelContext: modelContext)
                            showingSummaryDialog = false
                        },
                        onCancel: { showingSummaryDialog = false }
                    )
                }
            }
        }
    }

    private func resolveType(_ name: String) -> (name: String, icon: String, color: Color) {
        if let builtin = ActivityType(rawValue: name) {
            return (builtin.rawValue, builtin.icon, builtin.color)
        }
        if let custom = customTypes.first(where: { $0.name == name }) {
            return (custom.name, custom.symbol, custom.color)
        }
        return (name, "circle.fill", .gray)
    }

    private func startCustomActivity(_ custom: CustomActivityType) {
        if let existing = viewModel.currentSession {
            viewModel.endSession(existing, summary: nil, modelContext: modelContext)
        }
        let session = ActivitySession(activityType: .work, startTime: Date())
        session.activityType = custom.name
        modelContext.insert(session)
        viewModel.currentSession = session
        viewModel.elapsedTime = 0
        // Start timer via a fresh startActivity-equivalent
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak viewModel] _ in
            guard let vm = viewModel, let s = vm.currentSession else { return }
            vm.elapsedTime = Date().timeIntervalSince(s.startTime)
        }
        RunLoop.main.add(timer, forMode: .common)
        try? modelContext.save()
    }

    private func startActivity(name: String) {
        if let builtin = ActivityType(rawValue: name) {
            viewModel.startActivity(builtin, modelContext: modelContext)
        } else if let custom = customTypes.first(where: { $0.name == name }) {
            startCustomActivity(custom)
        }
    }
}

// MARK: - Activity Tile

struct ActivityTile: View {
    let name: String
    let icon: String
    let color: Color
    let isActive: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(color)
                    )

                if isActive {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }

            Text(name)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            isActive ?
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.4), lineWidth: 1.5)
                : nil
        )
    }
}

// MARK: - New Activity Type Sheet

struct NewActivityTypeSheet: View {
    let defaultCategory: ActivityCategory
    let onSave: (String, String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedSymbol = "star.fill"
    @State private var selectedColorHex = "3355CC"
    @State private var selectedCategory: ActivityCategory
    @FocusState private var nameFocused: Bool

    init(defaultCategory: ActivityCategory, onSave: @escaping (String, String, String, String) -> Void) {
        self.defaultCategory = defaultCategory
        self.onSave = onSave
        _selectedCategory = State(initialValue: defaultCategory)
    }

    var body: some View {
        NavigationStack {
            List {
                // Preview
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColorHex).opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: selectedSymbol)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Color(hex: selectedColorHex))
                        }
                        Text(name.isEmpty ? "Activity Name" : name)
                            .font(.headline)
                            .foregroundStyle(name.isEmpty ? .tertiary : .primary)
                    }
                    .padding(.vertical, 4)
                }

                // Name
                Section("Name") {
                    TextField("e.g. Surfing", text: $name)
                        .focused($nameFocused)
                }

                // Category
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ActivityCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Color
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(ActivityColorPalette.colors, id: \.hex) { item in
                            Circle()
                                .fill(Color(hex: item.hex))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    selectedColorHex == item.hex ?
                                        Circle().stroke(Color.primary, lineWidth: 2.5).padding(2)
                                        : nil
                                )
                                .onTapGesture { selectedColorHex = item.hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Symbol
                Section("Symbol") {
                    ForEach(ActivitySymbolPalette.all, id: \.label) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(group.symbols, id: \.self) { sym in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedSymbol == sym ?
                                                  Color(hex: selectedColorHex).opacity(0.15) :
                                                  Color(.tertiarySystemFill))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: sym)
                                            .font(.system(size: 18))
                                            .foregroundStyle(selectedSymbol == sym ?
                                                             Color(hex: selectedColorHex) : .secondary)
                                    }
                                    .overlay(
                                        selectedSymbol == sym ?
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(hex: selectedColorHex), lineWidth: 1.5)
                                            : nil
                                    )
                                    .onTapGesture { selectedSymbol = sym }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name.trimmingCharacters(in: .whitespaces),
                               selectedSymbol,
                               selectedColorHex,
                               selectedCategory.rawValue)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { nameFocused = true }
        }
    }
}

#Preview {
    ActivitiesView()
        .environment(ActivityTrackerViewModel())
        .modelContainer(for: [ActivitySession.self, CustomActivityType.self], inMemory: true)
}
