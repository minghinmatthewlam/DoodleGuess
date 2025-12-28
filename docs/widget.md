---
summary: Widget extension and App Group data sharing
read_when: [widget, extension, app group, shared data, home screen]
---

# Widget Extension

## Overview
Home screen widget displays latest drawing from partner.

## App Group
- ID must match in both entitlements:
  - `App/DoodleGuess.entitlements`
  - `DoodleWidget/DoodleWidget.entitlements`
- Used to share data between main app and widget

## Key Files
- `DoodleWidget/`: Widget extension code
- `Shared/`: App Group shared code for widget cache
- `starter_doodle`: Default image when no drawing available

## Data Flow
1. Main app saves drawing to App Group container
2. Widget reads from App Group container
3. Widget refreshes on timeline or user action
