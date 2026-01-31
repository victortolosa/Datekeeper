# Swift Implementation Plan — "Datekeeper" iOS App

This document serves as the technical specification and roadmap for building the native iOS client for **Datekeeper**. It outlines the architecture, data models, and phased execution plan to build a premium, native experience from the ground up, connecting to the existing Firebase backend.

## 1. Project Goal
Build a modern, native iOS application using **SwiftUI** and **iOS 17+** technologies. The app will provide a fluid, offline-first experience for tracking events and reminders, leveraging a shared Firebase backend.

**Key Technical Decisions:**
- **Minimum Target**: iOS 17.0 (Enables `@Observable` macro and modern Animation APIs).
- **Architecture**: MVVM (Model-View-ViewModel) with modular services.
- **Backend / Auth**: Google Firebase (Firestore, Auth, Storage).
- **UI Framework**: SwiftUI.

---

## 2. Architecture & Tech Stack

### **Core Stack**
- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Concurrency**: Swift Async/Await
- **Dependency Injection**: Factory (or lightweight native DI)

### **Data Layer**
- **Database**: Cloud Firestore (NoSQL).
- **ORM-like Layer**: `FirebaseFirestoreSwift` (`Codable` support).
- **Offline Strategy**:
  - Enable Firestore offline persistence.
  - Listen to snapshot updates for real-time sync.

### **Asset Management**
- **Images**: **NukeUI** (Lazy loading, caching, preheating).
- **Icons**: SF Symbols.

---

## 3. Data Models (Swift Strict)

The application will strictly adhere to the following `Codable` structs to ensure compatibility with the existing backend schema.

### **Configuration**
```swift
struct GradientConfig: Codable, Hashable {
    var colors: [String] // ["#hex", ...]
    var seed: Int?
}
```

### **Domain Entities**

#### **Tracker**
*Counts days since or until a target date.*
```swift
struct Tracker: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var targetDate: Date
    var type: String // "since" | "till"
    var category: String
    var colorTheme: String
    var gradientConfig: GradientConfig?
    var imageUrl: String?
    var displayUnits: [String]? // e.g. ["years", "months", "days"]
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
}
```

#### **Reminder**
*Simple one-off notifications.*
```swift
struct Reminder: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var description: String?
    var date: Date
    var category: String
    var colorTheme: String
    var gradientConfig: GradientConfig?
    @ServerTimestamp var createdAt: Date?
}
```

#### **Event**
*Recurring calendar events.*
```swift
struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var startDate: Date
    var recurrenceRule: String // iCal RRULE format
    var category: String
    var colorTheme: String
    var gradientConfig: GradientConfig?
    @ServerTimestamp var createdAt: Date?
}
```

#### **DailyEntry**
*Journal/Diary entries.*
```swift
struct DailyEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var date: Date
    var imageUrl: String?
    var notes: String?
    var moodRating: Int? // 1-5
    @ServerTimestamp var createdAt: Date?
}
```

---

## 4. Key Feature Implementation Strategy

### **A. Mesh Gradients**
*Requirement: Premium, organic backgrounds.*
- **Implementation**:
  - **iOS 18+**: Use native `MeshGradient`.
  - **iOS 17**: Fallback to `Canvas` with blurred, animated circles or a Metal shader implementation.
- **Logic**: Port the HSL-based color generation to a Swift `ColorUtils` helper to deterministicly generate palettes from a seed color.

### **B. Recurrence Engine**
*Requirement: Handle complex repeating schedules.*
- **Library**: `RRuleSwift` (or similar maintained package).
- **Logic**: Expand RRULE strings into concrete `Date` occurrences for display in lists.

### **C. Images & Media**
*Requirement: Performant image uploads and viewing.*
- **Upload**: Convert `PHPickerResult` → `UIImage` → `JPEG Data` (0.8 quality) → Firebase Storage.
- **Storage Paths**:
  - `entries/{uid}/{filename}.jpg`
  - `milestones/{uid}/{filename}.jpg`
- **Caching**: Configure Nuke to cache aggressively on disk.

### **D. Local Notifications**
*Requirement: Remind users of upcoming items.*
- **Framework**: `UserNotifications`.
- **Strategy**: Schedule up to 64 local notifications based on upcoming Reminders and calculated Event occurrences. Reschedule on app background/foreground.

---

## 5. Roadmap & Sprints

This plan targets a **6-week MVP build** with one engineer.

### **Sprint 1: Foundation (Weeks 1-2)** ✅ [COMPLETED]
*Focus: Project setup, Auth, and reading data.*

1. **Project Scaffold**:
   - [x] Initialize Xcode Project (SwiftUI App Lifecycle).
   - [x] Install dependencies (Firebase, Nuke, SwiftLint).
   - [x] Configure `GoogleService-Info.plist`.
2. **Authentication**:
   - [x] Implement `AuthService` (Singleton).
   - [x] Build `LoginView` & `SignUpView`.
   - [x] Implement "Session Boot" (Auto-login on launch).
3. **Data Layer**:
   - [x] Create all `Codable` models.
   - [x] Implement generic `FirestoreService<T>`.
   - [x] Verify reading a list of Trackers from the live DB.

### **Sprint 2: Core UX (Weeks 3-4)** ✅ [COMPLETED]
*Focus: Creating and managing content.*

1. **Trackers Feature**:
   - [x] `TrackersListView`: Grid/List toggle, mesh backgrounds.
   - [x] `TrackerDetailView`: Large countdown timer, confetti effects.
   - [x] `EditTrackerView`: Form with validation.
   - [x] **Crucial**: Implement custom "Time Ago" formatter.
2. **Media Integration**:
   - [x] Build generic `ImagePicker` component.
   - [x] Implement `StorageService` for upload/delete.
   - [x] Integrate image cropping (Native PHPicker used).
3. **Reminders Feature**:
   - [x] Simple list view independent of Trackers.
   - [x] Quick "Add Reminder" sheet.

### **Sprint 3: Polish & Launch (Weeks 5-6)** 🚧 [PENDING / NEXT]
*Focus: Advanced features and app store readiness.*

1. **Events & RRule**:
   - Integrate RRule parser.
   - Build calendar-aware logic to show "Next Occurrence".
2. **Offline & Sync**:
   - Test airplane mode behavior.
   - Add empty states and error banners.
3. **UI Polish**:
   - Implement `MeshGradient` visuals.
   - Add haptic feedback (Haptics).
   - Typography & Dark Mode audit.
4. **Release**:
   - TestFlight build.
   - App Store screenshots.
