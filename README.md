# Productivity Tracker - macOS

A privacy-first, native macOS app for tracking productivity and analyzing screen time with beautiful "liquid glass" design.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-native-green)

## Overview

Productivity Tracker is a native macOS application that helps you understand how you spend your time on your Mac. It tracks per-app and per-window screen time, automatically categorizes activities, and provides rich visualizations—all while keeping your data completely private and local.

### Key Features

✅ **Automatic Tracking**
- Monitors active app, window title, and browser URLs
- Aggregates usage into meaningful sessions
- Handles context switches gracefully with configurable debounce

✅ **Smart Categorization**
- Rule-based system for custom categorization
- Built-in heuristic classifier
- Extensible ML classification interface (for future)
- Categories: Work, Leisure, Research, Communication, Uncategorized

✅ **Rich Analytics**
- Interactive charts (Swift Charts)
- Time range filters (today, last 7 days, last 30 days, custom)
- Per-category stacked bar charts
- Per-app usage breakdown
- Daily timeline visualization

✅ **Privacy First**
- 100% local data storage (Core Data)
- No network requests
- No telemetry or analytics
- Panic button to delete all data
- Configurable data retention

✅ **Native macOS Experience**
- Built with SwiftUI + AppKit
- "Liquid glass" design with system materials
- Menubar extra for quick access
- Follows Apple Human Interface Guidelines
- Light/dark mode support

## Screenshots

### Dashboard
The main dashboard shows today's activity summary with category breakdown and top apps.

### Analytics
Comprehensive analytics with charts, time range filters, and timeline views.

### Rules Management
Define custom rules to automatically categorize activities by app, URL, or window title.

### Menubar Extra
Quick stats and controls accessible from the menubar.

## Architecture

### High-Level Design

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (SwiftUI Views: Dashboard, Analytics, Rules, Settings) │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                    Service Layer                         │
│  TrackingService │ CategoryService │ RuleEngine          │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                   Platform Layer                         │
│  WindowTracker │ BrowserURLDetector │ IdleMonitor       │
│  (CGWindowList │ AppleScript │ CGEventSource)           │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                    Data Layer                            │
│           Core Data (PersistenceController)             │
└─────────────────────────────────────────────────────────┘
```

### Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Local persistence with relationships and migrations
- **Swift Charts**: Native charting framework (macOS 13+)
- **CGWindowList**: Window information API
- **NSWorkspace**: Active app detection
- **NSAppleScript**: Browser URL extraction
- **System Materials**: `.regularMaterial`, `.ultraThinMaterial` for liquid glass effect

### Persistence Choice: Core Data

**Why Core Data over SQLite?**
1. Native SwiftUI integration with `@FetchRequest`
2. Automatic UI updates via `NSFetchedResultsController`
3. Built-in migration support
4. Relationship management
5. Better for time-series data with complex queries
6. iCloud sync capability (future)

### APIs and Permissions

| API | Purpose | Permission Required |
|-----|---------|-------------------|
| `NSWorkspace.shared.frontmostApplication` | Active app detection | None |
| `CGWindowListCopyWindowInfo` | Window titles | Screen Recording |
| `NSAppleScript` (Safari/Chrome) | Browser URLs | Automation |
| `CGEventSource.secondsSinceLastEventType` | Idle detection | None |

**Permission Flow:**
1. On first launch, app requests Screen Recording permission
2. User must manually enable in System Settings
3. App gracefully degrades if permissions denied

## Installation

### Requirements
- macOS 13.0 (Ventura) or later
- Xcode 15.0+ (for building)
- Swift 5.9+

### Building from Source

1. **Clone the repository**
   ```bash
   cd onscreen
   ```

2. **Open in Xcode**
   ```bash
   open ProductivityTracker/ProductivityTracker.xcodeproj
   ```

3. **Configure the project**
   - Select your Development Team in Signing & Capabilities
   - Update Bundle Identifier if needed
   - Review `Info.plist` for privacy descriptions

4. **Build and Run**
   - Select "My Mac" as target
   - Press ⌘R to build and run

5. **Grant Permissions**
   - On first launch, grant Screen Recording permission
   - Go to System Settings → Privacy & Security → Screen Recording
   - Enable for Productivity Tracker
   - **Restart the app**

For detailed setup instructions, see [`Documentation/XCODE_SETUP.md`](ProductivityTracker/Documentation/XCODE_SETUP.md).

## Usage

### First Launch

1. **Grant Permissions**: Follow system prompts to grant Screen Recording and Automation permissions
2. **Start Tracking**: Tracking begins automatically
3. **Explore Dashboard**: View today's activity summary
4. **Define Rules**: Add custom categorization rules
5. **Analyze**: Explore analytics with different time ranges

### Menubar Extra

Click the chart icon in the menubar to:
- View current activity and category
- See today's total time and session count
- Pause/resume tracking
- Manually change category for current session
- Open main app window

### Defining Rules

Rules are evaluated in priority order (top to bottom):

1. **App Rule**: Matches bundle ID or app name
   - Example: `xcode` → Work

2. **URL Rule**: Matches browser URLs (supports wildcards)
   - Example: `*github.com*` → Work

3. **Title Rule**: Matches window titles (supports wildcards)
   - Example: `*documentation*` → Research

**Wildcard Support**: Use `*` for pattern matching
- `*github.com*` matches `https://github.com/user/repo`
- `*meeting*` matches "Team Meeting - Zoom"

### Exporting Data

Export your tracking data for external analysis:

1. Go to Settings → Data Export
2. Choose format: CSV or JSON
3. Select date range (respects data retention setting)
4. Save file

**CSV Format**: Includes all session data with timestamps
**JSON Format**: Structured data with metadata

### Privacy Controls

**Pause Tracking**: Stop tracking temporarily (Settings or menubar)

**Delete All Data**: Permanently remove all sessions and rules (Settings → Privacy → Delete All Data)

**Data Retention**: Configure auto-deletion of old data (3, 6, 12 months, or keep all)

## "Liquid Glass" Design

The app uses Apple's system materials to create a translucent, layered aesthetic:

- **`.regularMaterial`**: Main cards and panels
- **`.ultraThinMaterial`**: Sidebar and headers
- **Subtle shadows**: `Color.black.opacity(0.05)` with 10pt radius
- **Rounded corners**: 16pt continuous curves
- **Glass borders**: `Color.white.opacity(0.1)` stroke
- **Adaptive colors**: Automatically adjusts for light/dark mode

Design principles:
1. Minimalist and clean
2. System font (San Francisco) throughout
3. Subtle blur and translucency
4. Layered card-like sections
5. Accessibility-compliant contrast

## Configuration

### Tracking Settings

**Idle Timeout** (default: 5 minutes)
- Configurable in Settings → Tracking
- Stops tracking after specified inactivity

**Debounce Threshold** (default: 5 seconds)
- Configurable in Settings → Tracking
- Ignores context switches shorter than threshold

**Poll Interval** (default: 2 seconds)
- Hardcoded in `TrackingService.swift`
- Balance between accuracy and CPU usage

### Data Retention

Configure in Settings → Privacy:
- 3 months
- 6 months
- 12 months (default)
- Keep all

## Extending the App

### Adding ML Classification

The app includes a protocol for pluggable classifiers:

```swift
protocol ActivityClassifier {
    func classify(
        appName: String,
        bundleID: String,
        windowTitle: String?,
        url: String?
    ) -> ActivityCategory
}
```

To add ML-based classification:

1. Implement `ActivityClassifier` protocol
2. Use CoreML or CreateML for training
3. Replace `HeuristicClassifier` in `RuleEngine`

### Adding New Categories

1. Extend `ActivityCategory` enum in `Core/Models/Category.swift`
2. Add color and icon mappings
3. Update default rules in `CategoryService`

### Custom Visualizations

Charts are built with Swift Charts. To add new visualizations:

1. Create new view in `Presentation/Analytics/`
2. Use Core Data `@FetchRequest` for live data
3. Leverage `Chart` and mark types (`BarMark`, `LineMark`, etc.)

## Troubleshooting

### Window titles not captured
- **Cause**: Screen Recording permission not granted
- **Solution**: Go to System Settings → Privacy & Security → Screen Recording, enable for Productivity Tracker, restart app

### Browser URLs not captured
- **Cause**: Automation permission not granted or browser not supported
- **Solution**:
  - Grant Automation permission in System Settings
  - Supported browsers: Safari, Chrome, Edge, Brave
  - Firefox not supported (no AppleScript support)

### High CPU usage
- **Cause**: Poll interval too aggressive
- **Solution**: Increase `pollInterval` in `TrackingService.swift` (e.g., from 2.0 to 5.0 seconds)

### Data not persisting
- **Cause**: Core Data model mismatch or migration failure
- **Solution**: Delete app data at `~/Library/Application Support/com.yourcompany.productivitytracker/` and restart

### Charts not displaying
- **Cause**: Requires macOS 13.0+ for Swift Charts
- **Solution**: Ensure deployment target is macOS 13.0 or later

## Performance

- **CPU Usage**: < 1% average (2-second poll interval)
- **Memory**: ~50-100 MB typical
- **Disk Space**: ~1-5 MB per month of tracking data
- **Battery Impact**: Minimal (< 1% additional drain)

## Limitations

### Current Limitations
1. **Sandboxing**: Best run without sandbox for full functionality
2. **Browser Support**: Firefox URLs not captured (no AppleScript support)
3. **Multiple Displays**: Tracks frontmost window across all displays
4. **Offline Only**: No cloud sync (by design)

### Intentional Limitations (Privacy)
1. No screenshots or visual capture
2. No keystroke logging
3. No network monitoring
4. No clipboard access

## Roadmap

### Planned Features
- [ ] ML-based activity classification
- [ ] Goals and productivity targets
- [ ] Focus mode with notifications
- [ ] Weekly/monthly reports
- [ ] iCloud sync (optional)
- [ ] Widgets (macOS 14+)

### Under Consideration
- [ ] Time blocking recommendations
- [ ] Pomodoro timer integration
- [ ] Team analytics (for organizations)
- [ ] iOS companion app

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Code Style**: Follow Swift API Design Guidelines
2. **Architecture**: Maintain separation of concerns (MVVM pattern)
3. **Privacy**: Never add features that compromise local-only data
4. **Testing**: Add unit tests for business logic
5. **Documentation**: Update README and inline docs

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- **Apple**: SwiftUI, Core Data, Swift Charts
- **Community**: macOS developer community for API guidance
- **Design**: Inspired by macOS Big Sur+ design language

## Support

For issues, questions, or feature requests:
- **GitHub Issues**: [Create an issue](https://github.com/yourusername/productivity-tracker/issues)
- **Documentation**: See `Documentation/` folder
- **Xcode Setup**: See `Documentation/XCODE_SETUP.md`

## Privacy Statement

Productivity Tracker is designed with privacy as the top priority:

✅ **All data stored locally** on your Mac
✅ **No network requests** to external servers
✅ **No telemetry or analytics** collection
✅ **No account or sign-in** required
✅ **Open source** - audit the code yourself

Your productivity data is yours alone.

---

**Built with ❤️ for macOS developers and productivity enthusiasts**
