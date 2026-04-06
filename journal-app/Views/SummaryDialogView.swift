// journal-app/journal-app/Views/SummaryDialogView.swift

import SwiftUI

struct SummaryDialogView: View {
    let viewModel: ActivityTrackerViewModel
    let session: ActivitySession
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var summaryText = ""
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
                        onSave(summaryText)
                    }
                    .font(.body.weight(.semibold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider()

                // Scrollable text area — fills all available space
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
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
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }

            }
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFocused = true
                }
            }
            .presentationDetents([.medium, .large], selection: $selectedDetent)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Skip") {
                        isTextFocused = false
                        onSave("")
                    }
                    .foregroundStyle(.secondary)

                    Button("Done") {
                        isTextFocused = false
                        onSave(summaryText)
                    }
                    .fontWeight(.semibold)
                }
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
