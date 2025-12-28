## 1) Merged final plan: best parts of both, without losing detail

What follows is a single Phase-1 plan that combines:

* Their stronger **SwiftUI app structure + setup steps + async/await services + UI flows**
* My stronger **offline-first drawing payload, robust pairing transactions, widget-never-empty strategy, better widget rendering, and deep link wiring**

### Decision summary (merged)

**Canvas:** PencilKit (`PKCanvasView`)
**Backend:** Firebase (Auth + Firestore + Cloud Functions + Messaging)
**Auth:** Firebase Anonymous Auth now; upgrade to Sign in with Apple later
**Drawing storage (merged best-of-both):**

* **Primary (recommended default):** Store `PKDrawing` bytes in Firestore (`drawingBytes`) for offline queueing and re-rendering.
* **Optional (add-on):** Also upload a rendered PNG to Firebase Storage and save `imageUrl` in Firestore (better for fast thumbnail grids and long-term scale).
  This merged model keeps offline correctness while preserving their scalable image hosting approach.

**Widget:** WidgetKit reads ONLY from App Group cached file + metadata.

* Never fetch network in widget.
* Always display an image: cached partner image OR bundled fallback doodle asset.
* Request refresh via `WidgetCenter.reloadTimelines()`, but don't depend on it being instant.

**Pairing (merged):**

* Keep their clean UX: "Your code" shown, partner enters code.
* Implement with my transaction-based `pairs/{code}` doc to avoid race conditions and guarantee single-use pairing.

---

## Part A — System architecture (merged)

### End-to-end flow (A → B widget)

```
User A draws (PencilKit PKDrawing)
        |
        | Send
        v
Firestore: drawings/{drawingId}
  - pairId
  - fromUserId
  - toUserId
  - createdAt
  - drawingBytes (PKDrawing data)  ✅ offline-friendly
  - imageUrl (optional, Storage)   ✅ scalable thumbnails

        |
        | Cloud Function trigger onCreate(drawings/{drawingId})
        v
FCM push to User B (data payload includes drawingId)

        |
        | App B receives push (best effort background), or sees it when opened
        v
App B Firestore listener (or fetch by drawingId)
  - decode drawingBytes -> render square PNG
  - write PNG + metadata to App Group shared container
  - WidgetCenter.reloadTimelines()

        |
        v
Widget reads latest_drawing.png + metadata.json (App Group)
  - displays image + "name • time ago"
  - deep link to app (optional but included)
```

Key merged principle: **widget shows local cache; app is responsible for keeping cache fresh**.

---

## Part B — Project setup (merged, step-by-step)

### Step 1: Create Xcode project

1. Xcode → New Project → **App**
2. Product Name: `DoodleGuess`
3. Interface: **SwiftUI**
4. Language: **Swift**
5. Minimum iOS: **16.0**

### Step 2: Add widget extension

1. File → New → Target → **Widget Extension**
2. Name: `DoodleWidget`
3. Uncheck "Include Configuration App Intent" (keep it static)

### Step 3: Configure App Groups (critical)

Do this for **both** targets.

1. Select project → `DoodleGuess` target → Signing & Capabilities
2. + Capability → **App Groups**
3. Add: `group.com.yourname.doodleguess`
4. Repeat for `DoodleWidget` target with the **same** identifier

### Step 4: Add capabilities for push

For `DoodleGuess` app target:

* + Capability → **Push Notifications**
* + Capability → **Background Modes**

  - Check **Remote notifications**
  - (Optional) Check **Background fetch** (can help but is not a guarantee)

### Step 5: Add Firebase SDK via SPM

1. File → Add Package Dependencies
2. Add: `https://github.com/firebase/firebase-ios-sdk`
3. Add to **DoodleGuess** target:

   * FirebaseAuth
   * FirebaseFirestore
   * FirebaseFirestoreSwift
   * FirebaseMessaging
   * FirebaseFunctions (optional for local calls; not needed for Cloud Functions triggers)
   * FirebaseStorage (optional if you enable imageUrl uploads)

### Step 6: Firebase console setup

1. Create Firebase project
2. Add iOS app:

   * Bundle ID must match Xcode
3. Download `GoogleService-Info.plist`
4. Add to Xcode project (app target)
5. Enable:

   * Authentication → Anonymous
   * Firestore Database (use test mode for initial dev)
   * Cloud Messaging
   * Cloud Functions
   * Storage (optional)

### Step 7: APNs + FCM

You will need APNs credentials to get reliable pushes on real devices.

* Apple Developer portal:

  * Create APNs Auth Key (.p8) with Push enabled
* Firebase console → Project Settings → Cloud Messaging

  * Upload APNs key

---

## Part C — Folder structure (merged)

This merges both structures; keep it simple but scalable:

```
DoodleGuess/
  App/
    DoodleGuessApp.swift
    AppDelegate.swift
    RootView.swift
    DeepLinkRouter.swift

  Features/
    Onboarding/
      WelcomeView.swift
      PairingView.swift
    Canvas/
      CanvasScreen.swift
      PencilKitCanvasView.swift
      CanvasViewModel.swift
      CanvasToolbar.swift
    History/
      HistoryView.swift
      DrawingDetailView.swift
    Settings/
      SettingsView.swift

  Models/
    AppUser.swift
    Pair.swift
    DrawingRecord.swift

  Services/
    AuthService.swift
    PairingService.swift
    DrawingService.swift

  Shared/
    AppGroup.swift
    SharedStorage.swift
    SharedModels.swift

DoodleWidget/
  DoodleWidget.swift
  DoodleWidgetBundle.swift
  Provider.swift
  WidgetView.swift
  Assets.xcassets (include starter_doodle)
```

**Important:** `Shared/` files used by the widget must be added to **both targets**.

---

## Part D — Implementation (merged code)

### 1) Shared App Group storage (merged: file + JSON metadata)

**Shared/AppGroup.swift**

```swift
import Foundation

enum AppGroup {
    static let id = "group.com.yourname.doodleguess"

    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) else {
            fatalError("Missing App Group container URL. Check entitlements for both targets.")
        }
        return url
    }
}
```

**Shared/SharedModels.swift**

```swift
import Foundation

struct WidgetDrawingMetadata: Codable {
    let partnerName: String
    let timestamp: Date
    let drawingId: String
}
```

**Shared/SharedStorage.swift**

```swift
import Foundation
import UIKit

/// App <-> Widget shared storage via App Group container.
/// - Stores image as a file (good practice; don't put large blobs in UserDefaults).
/// - Stores metadata as JSON (explicit, easy to debug).
enum SharedStorage {

    private static let imageFilename = "latest_drawing.png"
    private static let metadataFilename = "drawing_metadata.json"

    private static var imageURL: URL { AppGroup.containerURL.appendingPathComponent(imageFilename) }
    private static var metadataURL: URL { AppGroup.containerURL.appendingPathComponent(metadataFilename) }

    static func saveLatestDrawing(image: UIImage, metadata: WidgetDrawingMetadata) {
        // Save image
        if let data = image.pngData() {
            do { try data.write(to: imageURL, options: [.atomic]) }
            catch { print("❌ Failed to write image: \(error)") }
        }

        // Save metadata
        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metadataURL, options: [.atomic])
        } catch {
            print("❌ Failed to write metadata: \(error)")
        }
    }

    static func loadLatestDrawing() -> (image: UIImage?, metadata: WidgetDrawingMetadata?) {
        let image = UIImage(contentsOfFile: imageURL.path)

        var metadata: WidgetDrawingMetadata?
        if let data = try? Data(contentsOf: metadataURL) {
            metadata = try? JSONDecoder().decode(WidgetDrawingMetadata.self, from: data)
        }
        return (image, metadata)
    }

    static func hasDrawing() -> Bool {
        FileManager.default.fileExists(atPath: imageURL.path)
    }
}
```

**Widget "never empty" rule (merged improvement):**

* Add a bundled asset named **`starter_doodle`** to the widget's `Assets.xcassets`.
* If no cached drawing exists, widget displays `starter_doodle` (still a drawing, not a waiting state).

---

### 2) Firestore models (merged: bytes + optional imageUrl)

**Models/AppUser.swift**

```swift
import Foundation
import FirebaseFirestoreSwift

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var partnerId: String?
    var pairId: String?          // active pair doc id (same as code)
    var inviteCode: String       // code others can use to join your pair
    var deviceToken: String?
    var createdAt: Date

    static func generateInviteCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
```

**Models/Pair.swift**

```swift
import Foundation
import FirebaseFirestoreSwift

struct Pair: Codable, Identifiable {
    @DocumentID var id: String?
    var code: String
    var user1Id: String
    var user2Id: String?
    var createdAt: Date
}
```

**Models/DrawingRecord.swift**

```swift
import Foundation
import FirebaseFirestoreSwift

struct DrawingRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var pairId: String
    var fromUserId: String
    var toUserId: String
    var createdAt: Date

    // Merged storage: bytes-first, URL optional.
    var drawingBytes: Data?
    var imageUrl: String?
}
```

---

### 3) AuthService (their structure, with practical token handling)

**Services/AuthService.swift**

```swift
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class AuthService: ObservableObject {

    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = true

    private let db = Firestore.firestore()
    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        setupAuthListener()

        // Their pattern: listen for token posted by AppDelegate.
        NotificationCenter.default.addObserver(
            forName: Notification.Name("FCMTokenReceived"),
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let token = note.userInfo?["token"] as? String else { return }
            Task { await self?.updateDeviceToken(token) }
        }
    }

    private func setupAuthListener() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                guard let self else { return }
                if let firebaseUser {
                    await self.loadOrCreateUser(firebaseUserId: firebaseUser.uid)
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
                self.isLoading = false
            }
        }
    }

    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        await loadOrCreateUser(firebaseUserId: result.user.uid)
    }

    private func loadOrCreateUser(firebaseUserId: String) async {
        let ref = db.collection("users").document(firebaseUserId)

        do {
            let snap = try await ref.getDocument()

            if snap.exists, let user = try? snap.data(as: AppUser.self) {
                self.currentUser = user
                self.isAuthenticated = true
                return
            }

            // New user: generate inviteCode now
            let code = AppUser.generateInviteCode()
            let newUser = AppUser(
                id: firebaseUserId,
                name: "User",
                partnerId: nil,
                pairId: nil,
                inviteCode: code,
                deviceToken: nil,
                createdAt: Date()
            )

            try ref.setData(from: newUser)
            self.currentUser = newUser
            self.isAuthenticated = true

        } catch {
            print("❌ Error loadOrCreateUser: \(error)")
        }
    }

    func updateName(_ name: String) async {
        guard let userId = currentUser?.id else { return }
        do {
            try await db.collection("users").document(userId).updateData(["name": name])
            currentUser?.name = name
        } catch {
            print("❌ updateName failed: \(error)")
        }
    }

    func updateDeviceToken(_ token: String) async {
        guard let userId = currentUser?.id else { return }
        do {
            try await db.collection("users").document(userId).updateData(["deviceToken": token])
            currentUser?.deviceToken = token
        } catch {
            print("❌ updateDeviceToken failed: \(error)")
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
    }

    deinit {
        if let authListener { Auth.auth().removeStateDidChangeListener(authListener) }
        NotificationCenter.default.removeObserver(self)
    }
}
```

---

### 4) PairingService (merged: their UX, my transaction safety)

**Services/PairingService.swift**

```swift
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class PairingService: ObservableObject {

    @Published var isPaired = false
    @Published var partner: AppUser?
    @Published var isLoading = false
    @Published var error: String?

    private let db = Firestore.firestore()
    private var partnerListener: ListenerRegistration?

    /// Ensure the current user's invite code corresponds to an open pair doc they "own".
    /// This preserves their UI: you always have a shareable code.
    func ensurePairExistsForMyInviteCode(currentUser: AppUser) async {
        guard let myId = currentUser.id else { return }
        let code = currentUser.inviteCode.uppercased()

        let pairRef = db.collection("pairs").document(code)
        do {
            let snap = try await pairRef.getDocument()
            if snap.exists { return }

            // Create a new "open" pair doc.
            let pair = Pair(id: code, code: code, user1Id: myId, user2Id: nil, createdAt: Date())
            try pairRef.setData(from: pair)
        } catch {
            print("❌ ensurePairExistsForMyInviteCode error: \(error)")
        }
    }

    func joinWithCode(_ code: String, currentUserId: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let normalized = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count == 6 else {
            error = "Code must be 6 characters."
            throw PairingError.invalidCode
        }

        let pairRef = db.collection("pairs").document(normalized)
        let meRef = db.collection("users").document(currentUserId)

        try await db.runTransaction { txn, _ in
            let pairSnap = try txn.getDocument(pairRef)
            guard let data = pairSnap.data() else {
                throw PairingError.invalidCode
            }

            let user1Id = data["user1Id"] as? String ?? ""
            let user2Id = data["user2Id"] as? String

            if user1Id.isEmpty { throw PairingError.invalidCode }
            if user1Id == currentUserId { throw PairingError.selfPairing }
            if user2Id != nil { throw PairingError.alreadyPaired }

            // Claim spot as user2
            txn.updateData(["user2Id": currentUserId], forDocument: pairRef)

            // Update both users with pair + partner
            let user1Ref = self.db.collection("users").document(user1Id)
            txn.setData(["pairId": normalized, "partnerId": currentUserId], forDocument: user1Ref, merge: true)
            txn.setData(["pairId": normalized, "partnerId": user1Id], forDocument: meRef, merge: true)

            return user1Id
        }

        // Load partner doc and start listener
        try await loadPartnerAndListen(currentUserId: currentUserId)
    }

    func checkPairingStatus(currentUserId: String) async {
        do {
            let snap = try await db.collection("users").document(currentUserId).getDocument()
            guard let me = try? snap.data(as: AppUser.self),
                  let partnerId = me.partnerId else {
                isPaired = false
                partner = nil
                return
            }

            try await loadPartnerAndListen(currentUserId: currentUserId)

        } catch {
            print("❌ checkPairingStatus error: \(error)")
        }
    }

    private func loadPartnerAndListen(currentUserId: String) async throws {
        let mySnap = try await db.collection("users").document(currentUserId).getDocument()
        guard let me = try? mySnap.data(as: AppUser.self),
              let partnerId = me.partnerId else {
            isPaired = false
            partner = nil
            return
        }

        let partnerSnap = try await db.collection("users").document(partnerId).getDocument()
        if let partnerUser = try? partnerSnap.data(as: AppUser.self) {
            self.partner = partnerUser
            self.isPaired = true
            startPartnerListener(partnerId: partnerId)
        }
    }

    private func startPartnerListener(partnerId: String) {
        partnerListener?.remove()
        partnerListener = db.collection("users").document(partnerId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self, let snap else { return }
                guard let partner = try? snap.data(as: AppUser.self) else { return }

                Task { @MainActor in
                    // If partner clears partnerId, treat as disconnected.
                    if partner.partnerId == nil {
                        self.isPaired = false
                        self.partner = nil
                    } else {
                        self.partner = partner
                    }
                }
            }
    }

    func disconnect(currentUserId: String) async throws {
        guard let partnerId = partner?.id else { return }

        isLoading = true
        defer { isLoading = false }

        let batch = db.batch()
        let meRef = db.collection("users").document(currentUserId)
        let partnerRef = db.collection("users").document(partnerId)

        // Rotate codes for BOTH users (better for re-pairing after disconnect).
        let myNewCode = AppUser.generateInviteCode()
        let partnerNewCode = AppUser.generateInviteCode()

        batch.updateData([
            "partnerId": FieldValue.delete(),
            "pairId": FieldValue.delete(),
            "inviteCode": myNewCode
        ], forDocument: meRef)

        batch.updateData([
            "partnerId": FieldValue.delete(),
            "pairId": FieldValue.delete(),
            "inviteCode": partnerNewCode
        ], forDocument: partnerRef)

        try await batch.commit()

        partnerListener?.remove()
        isPaired = false
        partner = nil

        // Create a fresh pair doc for the current user's new code so it's immediately shareable.
        let newPairRef = db.collection("pairs").document(myNewCode)
        let newPair = Pair(id: myNewCode, code: myNewCode, user1Id: currentUserId, user2Id: nil, createdAt: Date())
        try? newPairRef.setData(from: newPair)
    }

    deinit { partnerListener?.remove() }
}

enum PairingError: LocalizedError {
    case invalidCode
    case selfPairing
    case alreadyPaired

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "Invalid pair code"
        case .selfPairing: return "Cannot pair with yourself"
        case .alreadyPaired: return "User is already paired"
        }
    }
}
```

This keeps their user-facing flow but fixes pairing correctness.

---

### 5) Drawing + rendering (merged: bytes-first, Storage optional)

#### Canvas rendering helper (my better widget rendering)

**Features/Canvas/CanvasViewModel.swift**

```swift
import Foundation
import PencilKit
import UIKit

@MainActor
final class CanvasViewModel: ObservableObject {
    let canvasView = PKCanvasView()

    @Published var selectedColor: UIColor = .black
    @Published var isErasing = false
    @Published var strokeWidth: CGFloat = 8

    init() {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
        applyTool()
    }

    func applyTool() {
        if isErasing {
            canvasView.tool = PKEraserTool(.vector)
        } else {
            canvasView.tool = PKInkingTool(.pen, color: selectedColor, width: strokeWidth)
        }
    }

    func clear() { canvasView.drawing = PKDrawing() }
    func undo() { canvasView.undoManager?.undo() }

    func drawingBytes() -> Data { canvasView.drawing.dataRepresentation() }

    func renderSquareImage(side: CGFloat = 512, background: UIColor = .white) -> UIImage {
        let drawing = canvasView.drawing

        if drawing.strokes.isEmpty {
            return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { ctx in
                background.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
            }
        }

        var bounds = drawing.bounds
        let pad: CGFloat = 24
        bounds = bounds.insetBy(dx: -pad, dy: -pad)

        let scale = min(side / bounds.width, side / bounds.height)
        let ink = drawing.image(from: bounds, scale: scale)

        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            background.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: side, height: side)).fill()
            let x = (side - ink.size.width) / 2
            let y = (side - ink.size.height) / 2
            ink.draw(in: CGRect(x: x, y: y, width: ink.size.width, height: ink.size.height))
        }
    }
}
```

**Features/Canvas/PencilKitCanvasView.swift**

```swift
import SwiftUI
import PencilKit

struct PencilKitCanvasView: UIViewRepresentable {
    @ObservedObject var vm: CanvasViewModel

    func makeUIView(context: Context) -> PKCanvasView { vm.canvasView }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        vm.applyTool()
    }
}
```

**Features/Canvas/CanvasToolbar.swift**

```swift
import SwiftUI

struct CanvasToolbar: View {
    @ObservedObject var vm: CanvasViewModel
    private let colors: [UIColor] = [.black, .systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple]

    var body: some View {
        HStack(spacing: 14) {
            Button { vm.isErasing = false; vm.applyTool() } label: {
                Image(systemName: "pencil").opacity(vm.isErasing ? 0.5 : 1)
            }

            Button { vm.isErasing = true; vm.applyTool() } label: {
                Image(systemName: "eraser").opacity(vm.isErasing ? 1 : 0.5)
            }

            ForEach(colors, id: \.self) { c in
                Button {
                    vm.selectedColor = c
                    vm.isErasing = false
                    vm.applyTool()
                } label: {
                    Circle()
                        .fill(Color(uiColor: c))
                        .frame(width: 22, height: 22)
                        .overlay(Circle().stroke(Color.primary.opacity(vm.selectedColor == c ? 0.8 : 0.2), lineWidth: 2))
                }
            }

            Spacer()

            Button { vm.undo() } label: { Image(systemName: "arrow.uturn.backward") }
            Button { vm.clear() } label: { Image(systemName: "trash") }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }
}
```

---

#### DrawingService (merged)

**Services/DrawingService.swift**

```swift
import Foundation
import UIKit
import PencilKit
import WidgetKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

@MainActor
final class DrawingService: ObservableObject {

    @Published var receivedDrawings: [DrawingRecord] = []
    @Published var sentDrawings: [DrawingRecord] = []
    @Published var latestReceivedDrawing: DrawingRecord?
    @Published var isSending = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage() // optional usage
    private var listener: ListenerRegistration?

    /// Send a drawing. Default path is bytes-only (offline-friendly).
    /// If uploadPNGToStorage = true, it also uploads a rendered PNG to Firebase Storage and saves imageUrl.
    func sendDrawing(
        pkDrawing: PKDrawing,
        renderedImage: UIImage,
        fromUserId: String,
        toUserId: String,
        pairId: String,
        uploadPNGToStorage: Bool = false
    ) async throws {
        isSending = true
        defer { isSending = false }

        let drawingId = UUID().uuidString
        let bytes = pkDrawing.dataRepresentation()

        var imageUrl: String? = nil

        if uploadPNGToStorage {
            // Optional scaling approach from the other plan:
            // store rendered PNG at ~512 or ~1024 depending on your choice.
            guard let png = renderedImage.pngData() else { throw DrawingError.invalidImage }

            let ref = storage.reference().child("drawings/\(drawingId).png")
            let meta = StorageMetadata()
            meta.contentType = "image/png"

            _ = try await ref.putDataAsync(png, metadata: meta)
            let url = try await ref.downloadURL()
            imageUrl = url.absoluteString
        }

        let record = DrawingRecord(
            id: drawingId,
            pairId: pairId,
            fromUserId: fromUserId,
            toUserId: toUserId,
            createdAt: Date(),
            drawingBytes: bytes,
            imageUrl: imageUrl
        )

        try db.collection("drawings").document(drawingId).setData(from: record)
    }

    func startListeningForDrawings(userId: String, partnerName: String) {
        listener?.remove()

        listener = db.collection("drawings")
            .whereField("toUserId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }
                if let error {
                    print("❌ drawings listener error: \(error)")
                    return
                }
                guard let docs = snap?.documents else { return }

                Task { @MainActor in
                    let drawings = docs.compactMap { try? $0.data(as: DrawingRecord.self) }
                    self.receivedDrawings = drawings

                    if let latest = drawings.first {
                        self.latestReceivedDrawing = latest
                        await self.updateWidgetFromDrawing(latest, partnerName: partnerName)
                    }
                }
            }
    }

    func loadSentDrawings(userId: String) async {
        do {
            let snap = try await db.collection("drawings")
                .whereField("fromUserId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments()

            self.sentDrawings = snap.documents.compactMap { try? $0.data(as: DrawingRecord.self) }
        } catch {
            print("❌ loadSentDrawings error: \(error)")
        }
    }

    /// Update widget cache:
    /// - Prefer bytes (offline-friendly)
    /// - Fallback to imageUrl download if needed
    func updateWidgetFromDrawing(_ drawing: DrawingRecord, partnerName: String) async {
        let image: UIImage?

        if let bytes = drawing.drawingBytes, let pk = try? PKDrawing(data: bytes) {
            image = renderSquareForWidget(drawing: pk)
        } else if let urlStr = drawing.imageUrl, let downloaded = await downloadImage(from: urlStr) {
            image = downloaded
        } else {
            image = nil
        }

        guard let image else { return }

        let metadata = WidgetDrawingMetadata(
            partnerName: partnerName,
            timestamp: drawing.createdAt,
            drawingId: drawing.id ?? ""
        )

        SharedStorage.saveLatestDrawing(image: image, metadata: metadata)
        WidgetCenter.shared.reloadTimelines(ofKind: "DoodleWidget")
    }

    func downloadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    private func renderSquareForWidget(drawing: PKDrawing) -> UIImage {
        let side: CGFloat = 512
        if drawing.strokes.isEmpty {
            return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
            }
        }

        var bounds = drawing.bounds.insetBy(dx: -24, dy: -24)
        let scale = min(side / bounds.width, side / bounds.height)
        let ink = drawing.image(from: bounds, scale: scale)

        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: side, height: side)).fill()
            let x = (side - ink.size.width) / 2
            let y = (side - ink.size.height) / 2
            ink.draw(in: CGRect(x: x, y: y, width: ink.size.width, height: ink.size.height))
        }
    }

    deinit { listener?.remove() }
}

enum DrawingError: LocalizedError {
    case invalidImage
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process drawing image."
        }
    }
}
```

**Why this merged service is the "best of both":**

* If you keep `uploadPNGToStorage = false` → offline-first and simplest.
* If you later need better history scrolling or unlimited complexity → turn on Storage uploads without rewriting your schema.

---

### 6) Canvas screen (merged: my rendering + their UX patterns)

**Features/Canvas/CanvasScreen.swift**

```swift
import SwiftUI
import PencilKit

struct CanvasScreen: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var pairing: PairingService
    @EnvironmentObject var drawings: DrawingService

    @StateObject private var vm = CanvasViewModel()

    @State private var showingSent = false
    @State private var sendError: String?

    var body: some View {
        VStack(spacing: 0) {
            PencilKitCanvasView(vm: vm)
                .background(Color.white)

            CanvasToolbar(vm: vm)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await send() }
                } label: {
                    if drawings.isSending {
                        ProgressView()
                    } else {
                        Text("Send").fontWeight(.semibold)
                    }
                }
                .disabled(drawings.isSending || vm.canvasView.drawing.strokes.isEmpty)
            }
        }
        .alert("Sent!", isPresented: $showingSent) {
            Button("OK") { vm.clear() }
        } message: {
            Text("Your drawing is on its way.")
        }
        .alert("Error", isPresented: Binding(
            get: { sendError != nil },
            set: { if !$0 { sendError = nil } }
        )) {
            Button("OK") { sendError = nil }
        } message: {
            Text(sendError ?? "Something went wrong.")
        }
    }

    private func send() async {
        guard let me = auth.currentUser?.id else {
            sendError = "Not signed in."
            return
        }
        guard let partnerId = pairing.partner?.id else {
            sendError = "Not connected to a partner."
            return
        }
        guard let pairId = auth.currentUser?.pairId ?? pairing.partner?.pairId ?? auth.currentUser?.pairId else {
            // In this merged design we store pairId on both users.
            // If missing, treat as pairing bug.
            sendError = "Missing pair information."
            return
        }

        let pk = vm.canvasView.drawing
        let rendered = vm.renderSquareImage(side: 512)

        do {
            // Default: bytes-only (offline-friendly). Enable Storage later if needed.
            try await drawings.sendDrawing(
                pkDrawing: pk,
                renderedImage: rendered,
                fromUserId: me,
                toUserId: partnerId,
                pairId: pairId,
                uploadPNGToStorage: false
            )
            showingSent = true
        } catch {
            sendError = error.localizedDescription
        }
    }
}
```

---

### 7) History + Settings (their completeness, minimal but runnable)

**Features/History/HistoryView.swift**

```swift
import SwiftUI
import PencilKit

struct HistoryView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var drawings: DrawingService

    var body: some View {
        List {
            Section("Received") {
                ForEach(drawings.receivedDrawings) { d in
                    NavigationLink {
                        DrawingDetailView(drawing: d)
                    } label: {
                        Text(d.id ?? "drawing")
                            .font(.caption)
                    }
                }
            }

            Section("Sent") {
                ForEach(drawings.sentDrawings) { d in
                    NavigationLink {
                        DrawingDetailView(drawing: d)
                    } label: {
                        Text(d.id ?? "drawing")
                            .font(.caption)
                    }
                }
            }
        }
        .task {
            if let me = auth.currentUser?.id {
                await drawings.loadSentDrawings(userId: me)
            }
        }
        .navigationTitle("History")
    }
}
```

**Features/History/DrawingDetailView.swift**

```swift
import SwiftUI
import PencilKit

struct DrawingDetailView: View {
    let drawing: DrawingRecord

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .background(Color.white)
            } else {
                ProgressView()
            }
        }
        .task {
            // Prefer bytes
            if let bytes = drawing.drawingBytes, let pk = try? PKDrawing(data: bytes) {
                image = renderFull(drawing: pk)
            } else if let url = drawing.imageUrl {
                image = await download(url)
            }
        }
        .navigationTitle("Drawing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func renderFull(drawing: PKDrawing) -> UIImage {
        // Render at higher resolution for full screen
        let side: CGFloat = 1024
        var bounds = drawing.bounds.insetBy(dx: -24, dy: -24)
        let scale = min(side / bounds.width, side / bounds.height)
        let ink = drawing.image(from: bounds, scale: scale)

        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: side, height: side)).fill()
            let x = (side - ink.size.width) / 2
            let y = (side - ink.size.height) / 2
            ink.draw(in: CGRect(x: x, y: y, width: ink.size.width, height: ink.size.height))
        }
    }

    private func download(_ urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch { return nil }
    }
}
```

**Features/Settings/SettingsView.swift**

```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var pairing: PairingService

    var body: some View {
        Form {
            Section("Partner") {
                Text(pairing.partner?.name ?? "Not connected")
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        if let me = auth.currentUser?.id {
                            try? await pairing.disconnect(currentUserId: me)
                        }
                    }
                } label: {
                    Text("Disconnect")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
```

---

### 8) App entry + navigation (their structure, plus deep link hooks)

**App/DoodleGuessApp.swift**

```swift
import SwiftUI
import FirebaseCore

@main
struct DoodleGuessApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var auth = AuthService()
    @StateObject private var pairing = PairingService()
    @StateObject private var drawings = DrawingService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(pairing)
                .environmentObject(drawings)
        }
    }
}
```

**App/RootView.swift**

```swift
import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var pairing: PairingService
    @EnvironmentObject var drawings: DrawingService

    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView("Loading...")
            } else if !auth.isAuthenticated {
                WelcomeView()
            } else if !pairing.isPaired {
                PairingView()
            } else {
                MainView()
            }
        }
        .task { await initialSetup() }
    }

    private func initialSetup() async {
        if !auth.isAuthenticated {
            try? await auth.signInAnonymously()
        }

        if let me = auth.currentUser {
            // Ensure my invite code has a pair doc behind it.
            await pairing.ensurePairExistsForMyInviteCode(currentUser: me)

            // Check pairing state (loads partner if paired)
            if let myId = me.id {
                await pairing.checkPairingStatus(currentUserId: myId)
            }

            // If paired, start listening for drawings
            if pairing.isPaired, let myId = auth.currentUser?.id, let partnerName = pairing.partner?.name {
                drawings.startListeningForDrawings(userId: myId, partnerName: partnerName)
            }
        }
    }
}
```

**MainView (simple nav)**

```swift
import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Draw") { CanvasScreen() }
                NavigationLink("History") { HistoryView() }
                NavigationLink("Settings") { SettingsView() }
            }
            .navigationTitle("Doodle Guess")
        }
    }
}
```

---

### 9) Onboarding views (their full UI, adapted)

**Features/Onboarding/WelcomeView.swift**

```swift
import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var auth: AuthService
    @State private var isSigningIn = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "pencil.tip.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(.blue, .blue.opacity(0.3))

            VStack(spacing: 12) {
                Text("Doodle Guess")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Draw for your partner.\nTheir drawing appears on your widget.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                Task {
                    isSigningIn = true
                    try? await auth.signInAnonymously()
                    isSigningIn = false
                }
            } label: {
                if isSigningIn {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSigningIn)
        }
        .padding(32)
    }
}
```

**Features/Onboarding/PairingView.swift**

```swift
import SwiftUI

struct PairingView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var pairing: PairingService

    @State private var showingJoinSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Text("Your Pair Code")
                        .font(.headline)

                    Text(auth.currentUser?.inviteCode ?? "------")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .tracking(8)

                    Button {
                        UIPasteboard.general.string = auth.currentUser?.inviteCode
                    } label: {
                        Label("Copy Code", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(32)
                .background(Color(.systemGray6))
                .cornerRadius(16)

                Text("Share this code with your partner,\nor enter their code below.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button {
                    showingJoinSheet = true
                } label: {
                    Text("Enter Partner's Code")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(32)
            .navigationTitle("Connect")
            .sheet(isPresented: $showingJoinSheet) {
                JoinPairSheet()
            }
        }
    }
}

struct JoinPairSheet: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var pairing: PairingService
    @Environment(\.dismiss) var dismiss

    @State private var code = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Enter your partner's 6-character code")
                    .font(.headline)

                TextField("ABC123", text: $code)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($focused)
                    .onChange(of: code) { _, newValue in
                        code = String(newValue.prefix(6)).uppercased()
                    }

                if let err = pairing.error {
                    Text(err).foregroundColor(.red).font(.caption)
                }

                Button {
                    Task {
                        guard let me = auth.currentUser?.id else { return }
                        try? await pairing.joinWithCode(code, currentUserId: me)
                        if pairing.isPaired { dismiss() }
                    }
                } label: {
                    if pairing.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Connect")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(code.count != 6 || pairing.isLoading)

                Spacer()
            }
            .padding(32)
            .navigationTitle("Join Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
    }
}
```

---

## Part E — Widget (merged: iOS 16 compatible, never empty, deep link)

### Widget entry + provider

**DoodleWidget/Provider.swift**

```swift
import WidgetKit
import SwiftUI
import UIKit

struct DoodleWidgetEntry: TimelineEntry {
    let date: Date
    let image: UIImage
    let partnerName: String
    let timestamp: Date?
    let drawingId: String?
}

struct DoodleWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> DoodleWidgetEntry {
        DoodleWidgetEntry(
            date: Date(),
            image: UIImage(named: "starter_doodle") ?? UIImage(),
            partnerName: "Partner",
            timestamp: nil,
            drawingId: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DoodleWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DoodleWidgetEntry>) -> Void) {
        let entry = loadEntry()

        // Request refresh periodically; iOS decides actual timing.
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> DoodleWidgetEntry {
        let (image, metadata) = SharedStorage.loadLatestDrawing()

        // Never empty: use cached image or bundled fallback.
        let fallback = UIImage(named: "starter_doodle") ?? UIImage()
        let finalImage = image ?? fallback

        return DoodleWidgetEntry(
            date: Date(),
            image: finalImage,
            partnerName: metadata?.partnerName ?? "Partner",
            timestamp: metadata?.timestamp,
            drawingId: metadata?.drawingId
        )
    }
}
```

### Widget view

**DoodleWidget/WidgetView.swift**

```swift
import SwiftUI
import WidgetKit

struct DoodleWidgetEntryView: View {
    let entry: DoodleWidgetEntry

    var body: some View {
        ZStack {
            Image(uiImage: entry.image)
                .resizable()
                .scaledToFill()
                .clipped()

            VStack {
                Spacer()
                HStack {
                    Text(entry.partnerName)
                        .font(.caption2)
                        .lineLimit(1)

                    Spacer()

                    if let ts = entry.timestamp {
                        // iOS 16-compatible relative time
                        Text(RelativeDateTimeFormatter().localizedString(for: ts, relativeTo: Date()))
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(.ultraThinMaterial)
            }
        }
        .widgetURL(deepLinkURL(entry.drawingId))
    }

    private func deepLinkURL(_ drawingId: String?) -> URL? {
        if let drawingId {
            return URL(string: "doodleguess://drawing?id=\(drawingId)")
        }
        return URL(string: "doodleguess://open")
    }
}
```

### Widget config + bundle

**DoodleWidget/DoodleWidget.swift**

```swift
import WidgetKit
import SwiftUI

struct DoodleWidget: Widget {
    let kind = "DoodleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DoodleWidgetProvider()) { entry in
            DoodleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Partner's Drawing")
        .description("See your partner's latest doodle.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

**DoodleWidget/DoodleWidgetBundle.swift**

```swift
import WidgetKit
import SwiftUI

@main
struct DoodleWidgetBundle: WidgetBundle {
    var body: some Widget {
        DoodleWidget()
    }
}
```

**Note on their iOS 17 `containerBackground`:** if you want the nicer iOS 17 widget background API later, add it behind `if #available(iOS 17, *) { ... }`.

---

## Part F — Push notifications (merged)

### AppDelegate (their pattern + background fetch hook)

**App/AppDelegate.swift**

```swift
import UIKit
import UserNotifications
import FirebaseMessaging

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        return true
    }

    func requestPushPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
        }
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        NotificationCenter.default.post(
            name: Notification.Name("FCMTokenReceived"),
            object: nil,
            userInfo: ["token": token]
        )
    }

    // Foreground presentation
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Optional: background push fetch hook (best-effort)
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.newData)
    }
}
```

**Where to request permission:** do it after pairing completes (or in onboarding), not on first frame.

---

## Part G — Cloud Function (include both versions; pick one)

### Version 1 style (their code)

```js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onNewDrawing = functions.firestore
  .document('drawings/{drawingId}')
  .onCreate(async (snap, context) => {
    const drawing = snap.data();
    const recipientId = drawing.toUserId;
    const senderId = drawing.fromUserId;

    const recipientDoc = await admin.firestore().collection('users').doc(recipientId).get();
    if (!recipientDoc.exists) return null;

    const deviceToken = recipientDoc.data().deviceToken;
    if (!deviceToken) return null;

    const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
    const senderName = senderDoc.exists ? senderDoc.data().name : 'Your partner';

    const message = {
      token: deviceToken,
      notification: {
        title: 'New Drawing! ',
        body: `${senderName} sent you a drawing`
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            'content-available': 1
          }
        }
      },
      data: {
        drawingId: context.params.drawingId,
        type: 'new_drawing'
      }
    };

    await admin.messaging().send(message);
    return null;
  });
```

### Version 2 style (my earlier style)

```js
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

exports.notifyNewDrawing = onDocumentCreated("drawings/{drawingId}", async (event) => {
  const data = event.data.data();
  const toUserId = data.toUserId;
  const fromUserId = data.fromUserId;

  const toUserSnap = await admin.firestore().doc(`users/${toUserId}`).get();
  const token = toUserSnap.get("deviceToken");
  if (!token) return;

  const fromUserSnap = await admin.firestore().doc(`users/${fromUserId}`).get();
  const senderName = fromUserSnap.exists ? (fromUserSnap.get("name") || "Your partner") : "Your partner";

  const message = {
    token,
    notification: { title: "New doodle", body: `${senderName} sent you a doodle` },
    data: { drawingId: event.params.drawingId, fromUserId, type: "new_doodle" },
    apns: { payload: { aps: { sound: "default", "content-available": 1 } } }
  };

  await admin.messaging().send(message);
});
```

Deploy (their detail):

```bash
cd functions
npm install
firebase deploy --only functions
```

---

## Part H — Milestones (merged checklists)

### Milestone 1: Project setup + local canvas

* [ ] App + Widget targets created
* [ ] App Groups configured on both targets
* [ ] PencilKit canvas draws with finger
* [ ] Color picker works (5-7 colors)
* [ ] Eraser works
* [ ] Undo works (use undo manager)
* [ ] Clear works
* [ ] Export render to square UIImage works (print size)

### Milestone 2: Firebase auth + user doc

* [ ] Firebase configured, plist added
* [ ] Anonymous auth enabled in console
* [ ] `AuthService` signs in and persists across launches
* [ ] `users/{uid}` created with `inviteCode`
* [ ] Invite code displayed in pairing UI

### Milestone 3: Pairing system (transaction-safe)

* [ ] `pairs/{inviteCode}` exists for current user
* [ ] Device B joins Device A's code
* [ ] Both user docs get `partnerId` and `pairId`
* [ ] Pairing persists after app restart
* [ ] Disconnect clears both sides and rotates codes

### Milestone 4: Send drawings (offline-friendly)

* [ ] Send creates `drawings/{drawingId}` with `drawingBytes`
* [ ] Works on Wi-Fi and cellular
* [ ] Airplane mode: send is queued (Firestore offline) and eventually delivers when online
* [ ] App doesn't crash when sending many drawings

### Milestone 5: Receive drawings + widget cache

* [ ] Firestore listener receives drawings (toUserId query)
* [ ] App renders drawing and saves to App Group
* [ ] Widget reads App Group and displays latest drawing
* [ ] Widget never shows empty/waiting (fallback doodle)
* [ ] Widget tap deep links (optional wiring)

### Milestone 6: Push notifications end-to-end

* [ ] APNs key uploaded to Firebase
* [ ] FCM token stored in user doc
* [ ] Cloud Function triggers on drawing create
* [ ] Push arrives on partner device reliably
* [ ] Tap push opens app (optional routing)
* [ ] (Best effort) background push hook does not crash

### Milestone 7: Polish + edge cases

* [ ] History view shows sent + received sorted newest-first
* [ ] Scroll remains smooth for many drawings
* [ ] App works after kill/relaunch
* [ ] Widget works after restart
* [ ] Poor network doesn't break core loop
* [ ] Two users can't "double join" same code (transaction ensures)
* [ ] Basic Settings: partner name + disconnect

---

## Part I — iOS concepts & gotchas (merged list)

**App Groups**

* Widget and app are separate processes. Use App Group container for shared files.
* Don't store big images in UserDefaults; store on disk.

**WidgetKit timeline**

* Widgets are not live views. You provide timeline entries; iOS decides refresh cadence.
* `WidgetCenter.reloadTimelines()` is a request, not a guarantee.

**Background modes**

* Remote notifications can give you best-effort background execution, but it's not guaranteed.
* Design so the widget still looks correct even if the app only updates cache when opened.

**SwiftUI state**

* `@StateObject` for objects created/owned by a view.
* `@ObservedObject` when passed in.
* `@EnvironmentObject` for app-wide services.

**Common mistakes**

* Forgetting to add shared files to both targets.
* Trying to fetch Firebase/network from the widget.
* Using iOS 17 widget APIs without availability guards while targeting iOS 16.
* Not testing push/widgets on real devices.

**Debug tips**

* Widget not updating:

  * Verify App Group id matches exactly
  * Confirm file is written to the shared container path
  * Remove and re-add widget
* Firebase issues:

  * Ensure `GoogleService-Info.plist` is in the app target
  * Ensure `FirebaseApp.configure()` called exactly once
* Push issues:

  * Check APNs key uploaded
  * Check user doc has `deviceToken`
  * Check Cloud Function logs

---

### Final "merged recommendation" in one sentence

Build Phase 1 with PencilKit + Firebase, store the canonical drawing as PKDrawing bytes in Firestore for offline reliability, optionally add Storage PNGs for thumbnails, and make the widget purely cache-driven via App Groups so it always shows a drawing.

If you want, I can also provide a minimal set of Firestore Security Rules for this schema (still MVP-level) so you aren't stuck in "test mode" longer than necessary.
