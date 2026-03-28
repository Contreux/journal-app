# Journal App

A simple iOS app for tracking daily activities with voice memo summaries.

## Features

- **Activity Tracking**: Tap an activity type to start tracking time
- **Voice Summaries**: Record voice memos that are transcribed to text using on-device speech recognition
- **Calendar View**: Browse your activity history by day in a monthly calendar view
- **Local Storage**: All data stored locally using SwiftData

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

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

- **SwiftUI** for the UI
- **SwiftData** for local persistence
- **Speech Framework** for on-device transcription (no network required)
- **AVFoundation** for audio recording

## Activity Types

- Gym, Running, Social, Work
- Side Project, Hobby, Cleaning
- Reading, Meditation, Cooking
- Commute, Meeting, Learning, Rest
