# Journal App

An iOS app for tracking daily activities with a clean, modern interface. Built with SwiftUI and SwiftData.

## Features

- **Activity Tracking**: Tap any activity to start tracking time with live duration display
- **Quick Start**: Recent activities appear for one-tap tracking
- **Today View**: See your active session, completed sessions, and daily totals at a glance
- **Activity Grid**: Browse activities organized by category (Body, Mind, Life)
- **Calendar View**: Browse your activity history by day in a monthly calendar view
- **Voice Summaries**: Record voice memos that are transcribed to text using on-device speech recognition
- **Session Notes**: Add notes to activities anytime — while running or after completion
- **Local Storage**: All data stored locally using SwiftData

## Requirements

- iOS 26.0+
- Xcode 26.0+
- Swift 6.0+

## Setup

1. Open `journal-app.xcodeproj` in Xcode
2. Update the bundle identifier in project settings
3. Add your Apple Developer Team ID
4. Build and run on your device or simulator

## Permissions

The app requires:
- **Microphone**: To record voice summaries
- **Speech Recognition**: To transcribe recordings to text

## Architecture

- **SwiftUI** for the UI with iOS 26 design patterns
- **SwiftData** for local persistence
- **Speech Framework** for on-device transcription (no network required)
- **AVFoundation** for audio recording
- **Observation** framework for state management

## Activity Types

Activities are organized into three categories:

**Body**
- Gym, Running, Meditation, Rest

**Mind**
- Work, Side Project, Learning, Reading

**Life**
- Social, Cooking, Cleaning, Commute, Meeting, Hobby

## TODO

- [ ] Add the ability to add comments to an activity while it's running (it shouldn't have to be stopped to add a comment)
- [ ] Add a widget so you can see the current session running
- [ ] Add the ability to add new categories
- [ ] Remove the Today page and replace with a smart "Quick Start" suggestion at the top of the Track page — learns from time-of-day patterns, only shows when no session is active
- [ ] Add meeting transcription: Record button on active session card → transcribe via ElevenLabs (cheap model) on session end → append to notes with speaker labels
- [ ] When ending a session, automatically prompt for notes by opening the activity in a dialog
- [ ] Add a live activity notification (like Uber) that shows on the Lock Screen and Dynamic Island while tracking
