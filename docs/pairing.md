---
summary: Invite code generation and partner pairing flow
read_when: [pairing, invite, partner, code, deep link, onboarding]
---

# Pairing Flow

## Overview
Two users pair via invite code to share drawings.

## Flow
1. User A generates invite code via `PairingService`
2. User A shares code (or deep link) with User B
3. User B enters code or taps deep link
4. `PairingService` creates `Pair` document linking both users
5. Both users' `AppUser.partnerUid` updated

## Key Files
- `Services/PairingService.swift`: Code generation, validation, pair creation
- `Features/Onboarding/`: Invite code entry UI
- `App/AppDelegate.swift`: Deep link handling

## Invite Code Format
- 6-character alphanumeric
- Expires after use or timeout
