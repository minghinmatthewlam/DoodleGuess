# TODO Backlog

## V1 Hardening

- Pairing: move invite code reservation/creation to server-side (Cloud Function) to avoid client collisions.
- Deep links: add a "loading/resolve" state for drawing fetch by id.
- Firestore rules: tighten `pairs` updates (prevent overwriting `user1Id`) and validate schema fields.
- Push: add background refresh flow to update widget cache on silent push (best-effort).
- Widget cache: clear cache on disconnect and add a simple version marker for invalidation.
