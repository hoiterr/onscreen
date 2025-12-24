# Architecture Documentation

## Table of Contents
1. [Overview](#overview)
2. [Layer Architecture](#layer-architecture)
3. [Data Flow](#data-flow)
4. [Core Components](#core-components)
5. [Design Decisions](#design-decisions)
6. [Platform APIs](#platform-apis)
7. [Liquid Glass Design System](#liquid-glass-design-system)

## Overview

Productivity Tracker follows a clean, layered architecture with clear separation of concerns. The app is structured around MVVM (Model-View-ViewModel) patterns with SwiftUI's reactive paradigm.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                          │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  Dashboard   │  │  Analytics   │  │    Rules     │         │
│  │     View     │  │     View     │  │     View     │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐                           │
│  │  Settings    │  │   MenuBar    │                           │
│  │     View     │  │   Popover    │                           │
│  └──────────────┘  └──────────────┘                           │
│                                                                  │
└───────────────────────────┬──────────────────────────────────────┘
                            │ @EnvironmentObject
                            │ @StateObject
┌───────────────────────────▼──────────────────────────────────────┐
│                       SERVICE LAYER                              │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │            TrackingService (ObservableObject)          │    │
│  │  • Polls active window every 2 seconds                 │    │
│  │  • Manages session lifecycle                           │    │
│  │  • Handles idle detection                              │    │
│  │  • Publishes current state                             │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │            CategoryService (ObservableObject)          │    │
│  │  • Initializes default rules                           │    │
│  │  • Calculates category statistics                      │    │
│  │  • Formats durations for display                       │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │            RuleEngine (ObservableObject)               │    │
│  │  • Applies rules in priority order                     │    │
│  │  • Falls back to heuristic classifier                  │    │
│  │  • Manages rule CRUD operations                        │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
└───────────────────────────┬──────────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────────┐
│                      PLATFORM LAYER                              │
│                                                                  │
│  ┌─────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ WindowTracker   │  │ BrowserURL       │  │ IdleMonitor  │  │
│  │                 │  │ Detector         │  │              │  │
│  ├─────────────────┤  ├──────────────────┤  ├──────────────┤  │
│  │ CGWindowList    │  │ NSAppleScript    │  │ CGEventSource│  │
│  │ NSWorkspace     │  │ (Safari/Chrome)  │  │              │  │
│  └─────────────────┘  └──────────────────┘  └──────────────┘  │
│                                                                  │
└───────────────────────────┬──────────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────────┐
│                        DATA LAYER                                │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │           PersistenceController (Singleton)            │    │
│  │  • Manages Core Data stack                             │    │
│  │  • CRUD operations for Sessions and Rules              │    │
│  │  • Export to CSV/JSON                                  │    │
│  │  • Data retention management                           │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │                    Core Data Model                      │    │
│  │                                                         │    │
│  │  SessionEntity                RuleEntity                │    │
│  │  ├─ id: UUID                  ├─ id: UUID              │    │
│  │  ├─ appName: String           ├─ name: String          │    │
│  │  ├─ bundleID: String          ├─ conditionType: String │    │
│  │  ├─ windowTitle: String?      ├─ pattern: String       │    │
│  │  ├─ url: String?              ├─ category: String      │    │
│  │  ├─ category: String          ├─ priority: Int16       │    │
│  │  ├─ startTime: Date           ├─ isEnabled: Bool       │    │
│  │  ├─ endTime: Date             └─ createdAt: Date       │    │
│  │  └─ duration: Double                                    │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Layer Architecture

### 1. Presentation Layer
**Responsibility**: User interface and user interactions

**Components**:
- **ContentView**: Main app shell with sidebar navigation
- **DashboardView**: Today's summary with cards
- **AnalyticsView**: Charts and time-based analytics
- **RulesView**: Rule management interface
- **SettingsView**: App settings and preferences
- **StatusBarController**: Menubar extra with popover

**Patterns**:
- SwiftUI declarative views
- `@EnvironmentObject` for shared services
- `@FetchRequest` for Core Data integration
- Observable objects for reactive updates

### 2. Service Layer
**Responsibility**: Business logic and state management

**Components**:
- **TrackingService**: Core tracking engine
  - Polls active window every 2 seconds
  - Creates and manages sessions
  - Handles window change detection
  - Integrates with platform APIs

- **CategoryService**: Category-related operations
  - Initializes default rules
  - Calculates statistics
  - Formats durations

- **RuleEngine**: Rule evaluation and management
  - Applies rules in priority order
  - Falls back to heuristic classifier
  - Manages rule CRUD

**Patterns**:
- `ObservableObject` for SwiftUI integration
- `@Published` properties for reactive updates
- Singleton pattern for shared services
- Dependency injection via initializers

### 3. Platform Layer
**Responsibility**: macOS API integration

**Components**:
- **WindowTracker**: Active window detection
  - Uses `NSWorkspace` for active app
  - Uses `CGWindowListCopyWindowInfo` for window titles
  - Permission checking and requesting

- **BrowserURLDetector**: Browser URL extraction
  - AppleScript integration for Safari/Chrome
  - Graceful degradation for unsupported browsers

- **IdleMonitor**: User activity detection
  - Uses `CGEventSource` for idle time
  - Configurable idle threshold

**Patterns**:
- Singleton pattern for system resources
- Error handling with optionals
- Graceful degradation on permission denial

### 4. Data Layer
**Responsibility**: Persistence and data management

**Components**:
- **PersistenceController**: Core Data wrapper
  - Manages persistent store
  - CRUD operations
  - Query helpers
  - Export functionality

- **Core Data Model**:
  - `SessionEntity`: Activity sessions
  - `RuleEntity`: Categorization rules

**Patterns**:
- Singleton for shared persistence
- Repository pattern via PersistenceController
- Entity + Extensions for computed properties

## Data Flow

### Tracking Flow

```
Timer (2s interval)
    │
    ├─▶ WindowTracker.getCurrentActiveWindow()
    │       │
    │       ├─▶ NSWorkspace.shared.frontmostApplication
    │       └─▶ CGWindowListCopyWindowInfo
    │
    ├─▶ BrowserURLDetector.getCurrentBrowserURL()
    │       │
    │       └─▶ NSAppleScript (Safari/Chrome)
    │
    ├─▶ IdleMonitor.isUserIdle()
    │       │
    │       └─▶ CGEventSource.secondsSinceLastEventType
    │
    └─▶ TrackingService.trackCurrentActivity()
            │
            ├─▶ RuleEngine.categorize()
            │       │
            │       ├─▶ Apply rules in order
            │       └─▶ HeuristicClassifier (fallback)
            │
            └─▶ PersistenceController.createSession()
                    │
                    └─▶ Core Data save
```

### UI Update Flow

```
Core Data Change
    │
    ├─▶ NSManagedObjectContext.save()
    │
    └─▶ @FetchRequest detects change
            │
            └─▶ SwiftUI View auto-updates
```

### Analytics Query Flow

```
User selects time range
    │
    ├─▶ PersistenceController.fetchSessions(from:to:)
    │       │
    │       └─▶ NSFetchRequest with predicate
    │
    ├─▶ CategoryService.getCategoryStats()
    │       │
    │       └─▶ Aggregate sessions by category
    │
    └─▶ Swift Charts renders visualization
```

## Core Components

### TrackingService

**Purpose**: Central tracking engine that monitors active windows and creates sessions.

**Key Responsibilities**:
1. Poll active window every N seconds (default: 2s)
2. Detect window changes
3. Create/end sessions with debounce threshold
4. Handle idle detection
5. Publish current state to UI

**State Management**:
```swift
@Published private(set) var isTracking: Bool
@Published private(set) var currentSession: SessionEntity?
@Published private(set) var currentWindow: ActiveWindow?
@Published private(set) var todayTotalDuration: TimeInterval
```

**Configuration**:
- `pollInterval`: 2.0 seconds (accuracy vs CPU trade-off)
- `debounceThreshold`: 5.0 seconds (ignore short switches)
- `idleThreshold`: 300 seconds via IdleMonitor

### RuleEngine

**Purpose**: Applies user-defined rules to categorize activities.

**Algorithm**:
1. Load rules sorted by priority
2. For each rule (in order):
   - Check if enabled
   - Apply pattern matching
   - Return category if match
3. Fall back to HeuristicClassifier if no match

**Pattern Matching**:
- **App**: Bundle ID or app name substring
- **URL**: Wildcard pattern matching
- **Title**: Wildcard pattern matching

**Extensibility**:
- Implements `ActivityClassifier` protocol
- Can be replaced with ML-based classifier

### PersistenceController

**Purpose**: Manages Core Data stack and provides data access layer.

**Core Data Stack**:
```swift
NSPersistentContainer
    ├─ NSPersistentStoreCoordinator
    ├─ NSManagedObjectModel (from .xcdatamodeld)
    └─ NSManagedObjectContext (viewContext)
```

**Key Operations**:
- `createSession()`: Create new session entity
- `updateSession()`: Update session end time and duration
- `fetchSessions(from:to:)`: Query sessions by date range
- `deleteAllData()`: Nuclear option for privacy
- `exportToCSV/JSON()`: Data export

## Design Decisions

### Why Core Data over SQLite?

| Criterion | Core Data | Raw SQLite |
|-----------|-----------|------------|
| SwiftUI Integration | ✅ Native `@FetchRequest` | ❌ Manual observation |
| Live Updates | ✅ Automatic | ❌ Manual refresh |
| Relationships | ✅ Built-in | ❌ Manual joins |
| Migrations | ✅ Automatic | ❌ Manual versioning |
| Type Safety | ✅ Swift entities | ❌ Weakly typed |
| Performance | ✅ Good for reads | ✅ Slightly faster writes |
| Learning Curve | ⚠️ Moderate | ⚠️ Moderate |

**Decision**: Core Data wins for SwiftUI integration and developer productivity.

### Why Polling vs Event-Based?

**Polling Approach** (Chosen):
```swift
Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { ... }
```

**Pros**:
- Simple and reliable
- Predictable CPU usage
- Easy to debug
- Handles all edge cases

**Cons**:
- Continuous CPU usage (minimal)
- May miss rapid switches

**Alternative** (Event-Based with `NSWorkspace` notifications):
```swift
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didActivateApplicationNotification
)
```

**Cons of Events**:
- Doesn't capture window title changes
- No URL change notifications
- Complex edge case handling
- Higher latency for idle detection

**Decision**: Polling at 2-second intervals provides best balance of accuracy, simplicity, and CPU efficiency.

### Why Timer over Combine?

**Timer Approach** (Chosen):
```swift
Timer.scheduledTimer(withTimeInterval:repeats:) { ... }
```

**Combine Alternative**:
```swift
Timer.publish(every: 2.0, on: .main, in: .common)
    .autoconnect()
    .sink { ... }
```

**Decision**: Timer is simpler, well-understood, and sufficient for this use case. Combine would add complexity without significant benefits.

### Why No CloudKit/iCloud Sync?

**Rationale**:
1. **Privacy First**: Local-only by design
2. **Simplicity**: No account management
3. **Trust**: Users can audit that no data leaves device
4. **Compliance**: No GDPR/privacy concerns

**Future**: Could add opt-in iCloud sync via NSUbiquitousStore.

### Why Debounce Threshold?

**Problem**: Users frequently switch between apps for < 5 seconds (e.g., checking messages, switching tabs).

**Solution**: Debounce threshold of 5 seconds.
- Sessions shorter than 5s are discarded
- Reduces noise in analytics
- More accurate representation of focused work

**Configurable**: Users can adjust in Settings.

### Why Idle Detection?

**Problem**: Users step away from computer but last app remains active.

**Solution**: Monitor idle time via `CGEventSource`.
- Default: 5 minutes
- Ends current session when idle
- Resumes tracking on activity

**Implementation**:
```swift
CGEventSource.secondsSinceLastEventType(
    .combinedSessionState,
    eventType: .mouseMoved
)
```

## Platform APIs

### CGWindowListCopyWindowInfo

**Purpose**: Get window titles for tracking.

**Usage**:
```swift
let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
```

**Permission**: Requires Screen Recording (macOS 10.15+)

**Limitations**:
- Cannot read window content
- Only reads window metadata (title, owner PID)
- User must manually grant permission

### NSAppleScript for Browser URLs

**Purpose**: Extract current browser URL for better categorization.

**Supported Browsers**:
- Safari: ✅ Full support
- Chrome: ✅ Full support
- Edge: ✅ Full support
- Brave: ✅ Full support
- Firefox: ❌ No AppleScript support

**Example**:
```applescript
tell application "Safari"
    if (count of windows) > 0 then
        get URL of current tab of front window
    end if
end tell
```

**Permission**: Requires Automation permission per browser.

**Graceful Degradation**: If permission denied or browser unsupported, returns `nil` and categorizes by app only.

### CGEventSource for Idle Time

**Purpose**: Detect user inactivity.

**Usage**:
```swift
let idleTime = CGEventSource.secondsSinceLastEventType(
    .combinedSessionState,
    eventType: .mouseMoved
)
```

**No Permission Required**: Public API.

**Events Monitored**:
- Mouse movement
- Keyboard input
- Trackpad gestures

## Liquid Glass Design System

### System Materials

SwiftUI provides built-in materials that adapt to light/dark mode:

```swift
.background(.regularMaterial)    // Cards, panels
.background(.ultraThinMaterial)  // Sidebar, headers
.background(.thickMaterial)      // Popovers (not used)
```

**Visual Effect**:
- Blurs content behind
- Vibrancy adjusts text for legibility
- Auto-adapts to appearance (light/dark)

### Glass Card Component

Custom reusable component for all cards:

```swift
struct GlassCard<Content: View>: View {
    var body: some View {
        content
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
```

**Design Elements**:
1. `.regularMaterial`: Frosted glass blur
2. `RoundedRectangle(cornerRadius: 16)`: Soft rounded corners
3. `.stroke(Color.white.opacity(0.1))`: Subtle glass edge
4. `.shadow(...)`: Depth and elevation

### Color System

**Semantic Colors** (adapt to appearance):
```swift
Color.primary      // Text
Color.secondary    // Muted text
Color.accentColor  // Interactive elements
```

**Category Colors**:
```swift
Work: .blue
Leisure: .green
Research: .purple
Communication: .orange
Uncategorized: .gray
```

### Typography

**System Font Stack** (San Francisco):
```swift
.font(.system(size: 32, weight: .bold, design: .rounded))  // Headers
.font(.headline)                                            // Section titles
.font(.subheadline)                                         // Body text
.font(.caption)                                             // Metadata
```

### Spacing Scale

Consistent spacing throughout:
```swift
4pt  - Tight spacing (icon + text)
8pt  - Small gaps
12pt - Default item spacing
16pt - Section spacing
24pt - Major section spacing
```

### Interactive Elements

**Buttons**:
```swift
.buttonStyle(.bordered)           // Secondary actions
.buttonStyle(.borderedProminent)  // Primary actions
.buttonStyle(.plain)              // Subtle actions
```

**Hover States**: Automatic via system styles

**Focus Rings**: Automatic for accessibility

### Accessibility

**VoiceOver**: All interactive elements labeled

**Contrast**: System materials ensure sufficient contrast

**Dynamic Type**: System fonts scale with user preferences

**Keyboard Navigation**: Full keyboard support via SwiftUI

---

## Summary

The architecture is designed for:
1. **Separation of Concerns**: Clear layers with defined responsibilities
2. **Testability**: Services are injectable and mockable
3. **Maintainability**: Well-organized, documented code
4. **Performance**: Efficient polling, optimized queries
5. **Privacy**: Local-only, no network, auditable
6. **Native Experience**: SwiftUI, system materials, HIG compliance

The "liquid glass" aesthetic leverages macOS's built-in materials and design language to create a beautiful, cohesive experience that feels native to the platform.
