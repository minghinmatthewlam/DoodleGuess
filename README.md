# DoodleGuess

Draw for your partner; their drawing appears on your home screen widget.

## Tech Stack

- **Language:** Swift
- **UI:** SwiftUI
- **Drawing:** PencilKit
- **Backend:** Firebase (Auth, Firestore, Cloud Functions, Messaging)
- **Widgets:** WidgetKit
- **Minimum iOS:** 16.0

## Features (MVP)

- Draw anything and send to your partner
- Partner's drawing appears on your home screen widget
- Push notifications when new drawing arrives
- Simple pairing via 6-character code

## Setup

> Setup instructions will be added once Xcode project is created.

1. Clone this repository
2. Open `DoodleGuess.xcodeproj` in Xcode
3. Add your `GoogleService-Info.plist` from Firebase Console
4. Configure App Groups for both app and widget targets
5. Build and run

## Project Structure

```
DoodleGuess/
├── App/                    # App entry, delegates, navigation
├── Features/
│   ├── Onboarding/         # Welcome, pairing views
│   ├── Canvas/             # Drawing screen
│   ├── History/            # Past drawings
│   └── Settings/           # App settings
├── Models/                 # Data models
├── Services/               # Auth, Pairing, Drawing services
└── Shared/                 # App Group shared code

DoodleWidget/               # Widget extension
├── Provider.swift
├── WidgetView.swift
└── Assets.xcassets
```

## License

Private project.
