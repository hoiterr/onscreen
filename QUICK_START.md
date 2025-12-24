# Quick Start Guide

Get Productivity Tracker running in **10 minutes**!

## Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Basic familiarity with Xcode

## Step 1: Create Xcode Project (2 min)

1. Open Xcode
2. **File → New → Project**
3. Choose **macOS → App**
4. Configure:
   - **Product Name**: `ProductivityTracker`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `None` (we'll add Core Data manually)
5. Click **Next**, choose location, **Create**

## Step 2: Add Source Files (3 min)

1. **Delete** the default `ContentView.swift` (we have our own)
2. **Delete** the default `ProductivityTrackerApp.swift` (we have our own)
3. In Finder, navigate to the `ProductivityTracker/` folder from this repo
4. **Drag and drop** all folders into your Xcode project:
   - `Core/`
   - `Data/`
   - `Platform/`
   - `Presentation/`
   - `ProductivityTrackerApp.swift`
5. When prompted, check:
   - ✅ **Copy items if needed**
   - ✅ **Create groups**
   - ✅ **Add to targets: ProductivityTracker**

Your project navigator should now show:
```
ProductivityTracker
├── Core/
├── Data/
├── Platform/
├── Presentation/
├── ProductivityTrackerApp.swift
└── Assets.xcassets
```

## Step 3: Create Core Data Model (2 min)

1. **File → New → File...**
2. Choose **Core Data → Data Model**
3. Name it: `ProductivityTracker` (will create `.xcdatamodeld`)
4. Click **Create**

### Add SessionEntity:
1. Click **Add Entity** button (bottom left)
2. Rename to `SessionEntity`
3. Click **Add Attribute** and add these 9 attributes:

| Attribute | Type | Optional |
|-----------|------|----------|
| id | UUID | ❌ No |
| appName | String | ✅ Yes |
| bundleID | String | ✅ Yes |
| windowTitle | String | ✅ Yes |
| url | String | ✅ Yes |
| category | String | ✅ Yes |
| startTime | Date | ✅ Yes |
| endTime | Date | ✅ Yes |
| duration | Double | ❌ No |

4. In **Data Model Inspector** (right panel):
   - Set **Codegen** to `Manual/None`
   - Set **Module** to `Current Product Module`

### Add RuleEntity:
1. Click **Add Entity** button
2. Rename to `RuleEntity`
3. Add these 8 attributes:

| Attribute | Type | Optional |
|-----------|------|----------|
| id | UUID | ❌ No |
| name | String | ✅ Yes |
| conditionType | String | ✅ Yes |
| pattern | String | ✅ Yes |
| category | String | ✅ Yes |
| priority | Int16 | ❌ No |
| isEnabled | Boolean | ❌ No |
| createdAt | Date | ✅ Yes |

4. In **Data Model Inspector**:
   - Set **Codegen** to `Manual/None`
   - Set **Module** to `Current Product Module`

5. **⌘S** to save

## Step 4: Configure Info.plist (1 min)

1. Select your app target in Xcode
2. Go to **Info** tab
3. Hover over any key and click **+** to add these keys:

| Key | Type | Value |
|-----|------|-------|
| Privacy - AppleEvents Sending Usage Description | String | `Productivity Tracker needs to access browser URLs to categorize your activity.` |
| Privacy - Screen Capture Usage Description | String | `Productivity Tracker needs Screen Recording permission to read window titles.` |

**Quick method**: Copy the `ProductivityTracker/Resources/Info.plist.template` contents and merge into your Info.plist.

## Step 5: Configure Signing (1 min)

1. Select your app target
2. Go to **Signing & Capabilities** tab
3. Enable **Automatically manage signing**
4. Select your **Team**
5. Leave **App Sandbox** OFF (or configure per entitlements template)

## Step 6: Build and Run! (1 min)

1. Select **My Mac** as the run destination
2. Press **⌘R** or click the **Play** button
3. Wait for build to complete (~30 seconds)
4. App launches!

## Step 7: Grant Permissions (2 min)

### Screen Recording Permission
1. On first launch, you'll see an alert about Screen Recording
2. Click **OK**
3. Go to **System Settings → Privacy & Security → Screen Recording**
4. Enable the checkbox for **ProductivityTracker**
5. **Restart the app**

### Automation Permission (Safari/Chrome)
1. When the app first tries to access a browser, a prompt appears
2. Click **OK** to allow
3. If you miss it, go to **System Settings → Privacy & Security → Automation**
4. Enable ProductivityTracker for Safari/Chrome

## ✅ You're Done!

The app is now tracking! Check:
- **Dashboard**: See today's activity
- **Analytics**: View charts (may be empty initially)
- **Rules**: Default rules are pre-loaded
- **Menubar**: Click the chart icon for quick stats

## Troubleshooting

### "ProductivityTracker.xcdatamodeld not found"
- Make sure the `.xcdatamodeld` file is in your project
- Check it's added to **Target Membership** (Inspector panel)

### "Cannot find 'SessionEntity' in scope"
- Build the project (⌘B) to generate Core Data classes
- Ensure Codegen is set to `Manual/None` for both entities

### Window titles not showing
- Grant Screen Recording permission
- **Restart the app** after granting permission

### Build errors about missing files
- Ensure all Swift files are in the project
- Check Target Membership for each file

### "SwiftUI Preview Failed"
- Ignore preview errors for now (they need mock data)
- Run the full app instead

## Next Steps

Once running:
1. ✅ Let it track for a few minutes
2. ✅ Check Dashboard for activity
3. ✅ Define custom rules in Rules tab
4. ✅ Explore Analytics with time ranges
5. ✅ Try exporting data (Settings)

## Full Documentation

For detailed information:
- **Xcode Setup**: `ProductivityTracker/Documentation/XCODE_SETUP.md`
- **Architecture**: `ProductivityTracker/Documentation/ARCHITECTURE.md`
- **Core Data Model**: `ProductivityTracker/Documentation/CORE_DATA_MODEL.md`
- **User Guide**: `README.md`

## Tips

### Performance
- Default poll interval: 2 seconds (good balance)
- Adjust in `TrackingService.swift` if needed

### Customization
- **Add categories**: Edit `Core/Models/Category.swift`
- **Change colors**: Modify `category.color` in `Category.swift`
- **Add default rules**: Edit `CategoryService.swift`

### Debugging
Enable Core Data SQL logging:
1. Edit scheme (⌘<)
2. Go to **Run → Arguments**
3. Add launch argument: `-com.apple.CoreData.SQLDebug 1`

## Common Questions

**Q: Can I distribute this app?**
A: Yes! For App Store, enable App Sandbox in entitlements. For direct distribution, sign with Developer ID certificate and notarize.

**Q: Does it work on older macOS?**
A: Requires macOS 13.0+ for Swift Charts. To support older versions, replace charts with custom visualizations.

**Q: How do I add ML-based classification?**
A: Implement the `ActivityClassifier` protocol with a CoreML model. Replace `HeuristicClassifier` in `RuleEngine`.

**Q: Where is data stored?**
A: `~/Library/Application Support/com.yourcompany.productivitytracker/ProductivityTracker.sqlite`

---

**That's it! You now have a fully functional productivity tracker running on your Mac.** 🎉

For issues or questions, see the main `README.md` or `Documentation/` folder.
