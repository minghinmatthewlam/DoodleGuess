---
summary: Firebase auth, Firestore models, and Cloud Functions setup
read_when: [firebase, auth, firestore, user, login, cloud function, push notification]
---

# Firebase Integration

## Authentication
- Anonymous auth on first launch via `AuthService`
- User document created in `users/{uid}`
- No account recovery (anonymous = ephemeral)

## Firestore Models

### AppUser (`users/{uid}`)
- User profile and partner link
- Contains `partnerUid` when paired

### Pair (`pairs/{pairId}`)
- Shared drawing state between two users
- Contains current drawing data

### DrawingRecord (`pairs/{pairId}/drawings/{drawingId}`)
- Archived drawings history

## Cloud Functions (`functions/`)
- Push notification on new drawing
- Deploy: `npm --prefix functions install && firebase deploy --only functions`

## Security Rules
- `firestore.rules`: Access control for Firestore
- Users can only read/write their own data and shared pair data
