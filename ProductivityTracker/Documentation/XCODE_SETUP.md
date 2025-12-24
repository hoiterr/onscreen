# Xcode Setup Guide for Productivity Tracker

This guide explains how to configure the Xcode project to compile and run the Productivity Tracker app.

## 1. Project Configuration

### Target Settings
- **Product Name**: ProductivityTracker
- **Bundle Identifier**: com.yourcompany.productivitytracker
- **Minimum Deployment**: macOS 13.0 or later
- **Swift Version**: Swift 5.9+

### Capabilities
Enable the following capabilities in your target:
1. **App Sandbox** → Turn OFF (or configure specific permissions)
   - Alternatively, if sandboxed, enable:
     - Screen Recording
     - Automation
     - File Access (for export)

### Signing & Capabilities
- Development Team: Select your team
- Signing Certificate: Automatic or manual

## 2. Required Frameworks

Add these frameworks to your target:
- `SwiftUI.framework`
- `CoreData.framework`
- `Charts.framework` (built-in macOS 13+)
- `AppKit.framework`
- `ApplicationServices.framework`

## 3. Info.plist Configuration

Add the following keys to your `Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Privacy Permissions -->
    <key>NSAppleEventsUsageDescription</key>
    <string>Productivity Tracker needs to access browser URLs to categorize your activity.</string>

    <key>NSScreenCaptureUsageDescription</key>
    <string>Productivity Tracker needs Screen Recording permission to read window titles for accurate tracking.</string>

    <!-- App Behavior -->
    <key>LSUIElement</key>
    <false/>

    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>

    <!-- App Category -->
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
</dict>
</plist>
```

## 4. Core Data Model Setup

### Create the Core Data Model

1. In Xcode, select **File → New → File...**
2. Choose **Data Model** under Core Data section
3. Name it: `ProductivityTracker.xcdatamodeld`
4. Add the following entities:

#### Entity: SessionEntity
| Attribute       | Type     | Optional | Indexed |
|----------------|----------|----------|---------|
| id             | UUID     | No       | Yes     |
| appName        | String   | Yes      | Yes     |
| bundleID       | String   | Yes      | Yes     |
| windowTitle    | String   | Yes      | No      |
| url            | String   | Yes      | No      |
| category       | String   | Yes      | Yes     |
| startTime      | Date     | Yes      | Yes     |
| endTime        | Date     | Yes      | Yes     |
| duration       | Double   | No       | No      |

**Indexes**: Create a compound index on `startTime` for faster queries.

#### Entity: RuleEntity
| Attribute       | Type     | Optional | Indexed |
|----------------|----------|----------|---------|
| id             | UUID     | No       | Yes     |
| name           | String   | Yes      | No      |
| conditionType  | String   | Yes      | No      |
| pattern        | String   | Yes      | No      |
| category       | String   | Yes      | Yes     |
| priority       | Int16    | No       | Yes     |
| isEnabled      | Boolean  | No       | No      |
| createdAt      | Date     | Yes      | No      |

**Indexes**: Create an index on `priority` for ordered queries.

### Code Generation
- For each entity, set **Codegen** to `Manual/None` in the Data Model Inspector
- The entity classes are provided in the `Data/Entities/` folder

## 5. Build Settings

### Other Linker Flags
If you encounter linker errors, add:
```
-framework ApplicationServices
-framework CoreGraphics
```

### Swift Compiler Flags
No special flags required for standard configuration.

## 6. Entitlements

If using App Sandbox, create an entitlements file with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>

    <key>com.apple.security.automation.apple-events</key>
    <true/>

    <!-- Note: Screen recording permission cannot be granted via entitlements -->
    <!-- User must manually grant in System Settings -->
</dict>
</plist>
```

**Important**: For **Screen Recording** permission, the app must request it at runtime. Users will see a system prompt and must manually enable it in:
```
System Settings → Privacy & Security → Screen Recording
```

## 7. File Organization

Organize your Xcode project groups to match the architecture:

```
ProductivityTracker/
├── ProductivityTrackerApp.swift
├── Core/
│   ├── Models/
│   │   ├── Category.swift
│   │   ├── ActivitySession.swift
│   │   └── Rule.swift
│   ├── Services/
│   │   ├── TrackingService.swift
│   │   ├── CategoryService.swift
│   │   └── RuleEngine.swift
│   └── Protocols/
│       └── ActivityClassifier.swift
├── Data/
│   ├── CoreData/
│   │   ├── PersistenceController.swift
│   │   └── ProductivityTracker.xcdatamodeld
│   └── Entities/
│       ├── SessionEntity.swift
│       └── RuleEntity.swift
├── Platform/
│   ├── WindowTracker.swift
│   ├── BrowserURLDetector.swift
│   └── IdleMonitor.swift
├── Presentation/
│   ├── ContentView.swift
│   ├── Dashboard/
│   │   └── DashboardView.swift
│   ├── Analytics/
│   │   └── AnalyticsView.swift
│   ├── Rules/
│   │   └── RulesView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── MenuBar/
│       └── StatusBarController.swift
└── Resources/
    ├── Info.plist
    └── Assets.xcassets
```

## 8. Permissions Testing

### First Launch
On first launch, the app will request permissions:

1. **Screen Recording**:
   - A system alert will appear
   - User must go to System Settings → Privacy & Security → Screen Recording
   - Enable permission for Productivity Tracker
   - **Restart the app** after granting permission

2. **Automation** (for browser URL detection):
   - When first accessing Safari/Chrome, a prompt will appear
   - User must allow automation access
   - If denied, URLs won't be captured (graceful degradation)

### Testing Permissions
To test permission requests:
```bash
# Reset Screen Recording permission
tccutil reset ScreenCapture com.yourcompany.productivitytracker

# Reset Automation permission
tccutil reset AppleEvents com.yourcompany.productivitytracker
```

## 9. Common Build Issues

### Issue: "Missing Core Data Model"
**Solution**: Ensure `ProductivityTracker.xcdatamodeld` is added to the target's "Compile Sources" build phase.

### Issue: "Screen Recording Permission Denied"
**Solution**: The app must run with elevated privileges. Disable sandboxing or ensure user has manually granted permission in System Settings.

### Issue: "Charts framework not found"
**Solution**: Ensure deployment target is macOS 13.0+. Charts is built into SwiftUI on macOS 13+.

### Issue: "Cannot read window titles"
**Solution**:
1. Check Info.plist has `NSScreenCaptureUsageDescription`
2. Verify app has Screen Recording permission
3. Restart app after granting permission

## 10. Building and Running

### Development Build
1. Open `ProductivityTracker.xcodeproj`
2. Select your development team
3. Choose "My Mac" as target
4. Build and Run (⌘R)

### Release Build
1. Set build configuration to Release
2. Archive the app (Product → Archive)
3. Export as "Mac App"
4. For distribution:
   - Code sign with Developer ID certificate
   - Notarize with Apple
   - Distribute as DMG or via App Store

## 11. Debugging Tips

### Enable Core Data Debugging
Add launch argument:
```
-com.apple.CoreData.SQLDebug 1
```

### Enable SwiftUI Debugging
Add launch argument:
```
-NSShowAllViews YES
```

### View Core Data Database
Database location:
```
~/Library/Application Support/com.yourcompany.productivitytracker/
```

## 12. Performance Considerations

- **Tracking Interval**: Default is 2 seconds. Adjust in `TrackingService.swift`
- **Core Data Batch Size**: Fetch requests use appropriate batch sizes
- **UI Updates**: Charts update efficiently with `@FetchRequest` and observable objects

## Next Steps

After successful build:
1. Test permissions workflow
2. Verify tracking captures data
3. Test all UI sections
4. Export data to validate persistence
5. Test menubar popover functionality

For questions or issues, refer to the main README.md or Apple's documentation on:
- [Requesting Access to Protected Resources](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/requesting_access_to_protected_resources)
- [Core Data Programming Guide](https://developer.apple.com/documentation/coredata)
