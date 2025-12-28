# Repository Guidelines

## Project Structure & Module Organization
- `App/`: app entry, `AppDelegate`, deep links, root navigation.
- `Features/`: UI screens by feature (`Onboarding/`, `Canvas/`, `History/`, `Settings/`).
- `Models/`: Firestore models (`AppUser`, `Pair`, `DrawingRecord`).
- `Services/`: Firebase-facing services (`AuthService`, `PairingService`, `DrawingService`).
- `Shared/`: App Group shared code for widget cache.
- `DoodleWidget/`: Widget extension and assets (includes `starter_doodle`).
- `DoodleGuessTests/`: unit tests for P0 loop.
- `functions/`: Firebase Cloud Function for push on new drawing.
- `firebase.json`, `firestore.rules`, `firestore.indexes.json`: Firebase config.

## Build, Test, and Development Commands
- `./scripts/bootstrap_xcodegen.sh`: install XcodeGen if needed.
- `./scripts/generate_xcodeproj.sh`: regenerate `DoodleGuess.xcodeproj` from `project.yml`.
- `./scripts/p0.sh`: fastest feedback loop (build app + widget + unit tests).
- `xcodebuild -scheme DoodleGuess build`: manual build if needed.

## Coding Style & Naming Conventions
- Swift style: follow Swift API Design Guidelines; prefer `camelCase` for vars/functions and `PascalCase` for types.
- Keep services `@MainActor` when they publish UI-facing state.
- Avoid `any`; fix types at the source. Use `#if canImport(...)` guards for Firebase-optional builds.

## Testing Guidelines
- Framework: XCTest in `DoodleGuessTests/`.
- P0 tests are required for each change; run `./scripts/p0.sh`.
- Naming: `*Tests.swift` with `test...` methods (e.g., `InviteCodeTests`).

## Commit & Pull Request Guidelines
- Commit messages are imperative and scoped (e.g., “Add Firebase config and Firestore rules”).
- Keep commits small and focused; avoid bundling unrelated changes.
- For PRs: include a brief summary, test command(s) run, and screenshots for UI changes.

## Security & Configuration Tips
- Do not commit real `GoogleService-Info.plist` to public remotes.
- App Group ID must match in `App/DoodleGuess.entitlements` and `DoodleWidget/DoodleWidget.entitlements`.
- Firebase deploys use `firebase.json` + `functions/` (`npm --prefix functions install`, then `firebase deploy --only functions`).
