---
title: Add swipe-to-delete to calendar session rows
type: feat
status: active
date: 2026-04-10
---

# Add Swipe-to-Delete to Calendar Session Rows

## Overview

Add swipe-to-delete functionality to session rows in the Calendar view, allowing users to quickly delete sessions with a swipe gesture instead of opening the edit sheet and tapping delete.

## Problem Frame

Currently, deleting a session from the calendar requires:
1. Tapping the session row to open the edit sheet
2. Scrolling down to find the Delete button
3. Confirming the deletion

This is too many steps for a common action. Users want to quickly remove sessions directly from the calendar list with a swipe gesture, which is the standard iOS pattern.

## Requirements Trace

- R1. Each session row in DaySessionsView must be swipeable from right-to-left
- R2. Swiping reveals a red "Delete" action button
- R3. Tapping Delete removes the session immediately with haptic feedback
- R4. The swipe action should not interfere with the existing tap-to-edit gesture
- R5. Deleted sessions are removed from SwiftData and the UI updates immediately

## Scope Boundaries

- Only affects CalendarView's DaySessionsView
- Does not add swipe-to-edit or other swipe actions (delete only)
- Does not change the SessionEditView delete functionality (keep as fallback)

## Context & Research

### Current Implementation

The calendar displays sessions in `DaySessionsView` (lines 259-313 of CalendarView.swift):

```swift
ForEach(sessions) { session in
    SessionRow(session: session, customTypes: customTypes)
        .onTapGesture { onTap(session) }
}
```

Sessions are displayed using `SessionRow` (lines 317-373), a custom view with:
- Activity icon and color
- Activity name and summary/time
- Duration
- Visual left-border accent

Currently, tapping a row opens `SessionEditView` which has its own delete button.

### Relevant Code Patterns

- SwiftUI's `.swipeActions` modifier is the standard iOS pattern for this
- ModelContext is already available via `@Environment` in CalendarView
- Session deletion pattern exists in `SessionEditView.onDelete` closure

## Key Technical Decisions

- **Use `.swipeActions`**: This is the native iOS 15+ API for swipe actions on list rows. It's accessible, supports haptics, and follows platform conventions.
- **Pass delete handler through view hierarchy**: DaySessionsView needs access to the modelContext or a delete callback. Options:
  - Option A: Pass `onDelete` closure from CalendarView -> DaySessionsView
  - Option B: Inject modelContext into DaySessionsView via environment
  - **Chosen: Option A** - More explicit, matches existing `onTap` pattern, easier to test

## Implementation Units

- [ ] **Unit 1: Add swipe-to-delete to SessionRow**

**Goal:** Make each session row swipeable with a delete action

**Requirements:** R1, R2, R3, R4, R5

**Dependencies:** None

**Files:**
- Modify: `journal-app/Views/CalendarView.swift`

**Approach:**
1. Update `DaySessionsView` to accept an `onDelete` closure (similar to existing `onTap`)
2. Pass the closure from `CalendarView` down to `DaySessionsView`
3. Wrap `SessionRow` in the ForEach with `.swipeActions` modifier
4. Add red delete button that calls `onDelete(session)`
5. Add haptic feedback on delete

**Technical design:**

```swift
// In DaySessionsView
let onDelete: (ActivitySession) -> Void

// In the ForEach
ForEach(sessions) { session in
    SessionRow(session: session, customTypes: customTypes)
        .onTapGesture { onTap(session) }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete(session)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
}
```

**Patterns to follow:**
- Existing `onTap` closure pattern in DaySessionsView
- `.destructive` role for delete actions (shows red background)
- `allowsFullSwipe: true` for quick delete by swiping all the way

**Test scenarios:**
- Happy path: Swipe on a session row, tap Delete, session is removed from list and database
- Edge case: Swipe on the only session for a day, empty state appears after deletion
- Integration: Deleted session no longer appears in calendar day dots or week summary
- Error path: Attempting to delete an already-deleted session (should be no-op)

**Verification:**
- Swiping right-to-left on any session row reveals red Delete button
- Tapping Delete removes session immediately without confirmation dialog
- Session is removed from SwiftData (verified by checking it's gone from other views)
- Haptic feedback occurs on delete
- Tap-to-edit still works normally when not swiping

## System-Wide Impact

- **Interaction graph:** Only affects CalendarView's session list
- **State lifecycle:** Standard SwiftData deletion - object removed from context and persisted
- **Unchanged invariants:** SessionEditView's delete button continues to work as before

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Accidental deletion | Use `allowsFullSwipe: false` if full swipe is too easy to trigger accidentally, or keep full swipe for power users |
| No confirmation dialog | Standard iOS pattern; users can re-create session if deleted by mistake |

## Sources & References

- Current code: `journal-app/Views/CalendarView.swift`
- SwiftUI swipeActions documentation: https://developer.apple.com/documentation/swiftui/view/swipeactions(edge:allowsfullswipe:content:)
