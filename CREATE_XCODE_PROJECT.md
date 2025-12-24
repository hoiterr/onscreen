# Quick Xcode Setup Guide

## Option 1: Fastest Method (Recommended)

1. **Open Xcode** and select "Create New Project"

2. **Choose template:**
   - macOS → App
   - Click Next

3. **Project settings:**
   - Product Name: `ProductivityTracker`
   - Organization Identifier: `com.yourcompany` (or your preference)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ✅ Use Core Data
   - ✅ Include Tests (optional)
   - Click Next

4. **Save location:**
   - Navigate to: `/home/user/onscreen`
   - **IMPORTANT:** Uncheck "Create Git repository" (we already have one)
   - Click Create

5. **Delete default files:**
   - Delete `ContentView.swift` (we have our own)
   - Delete `ProductivityTrackerApp.swift` (we have our own)
   - Keep `ProductivityTracker.xcdatamodeld` (we'll configure it)

6. **Add existing files:**
   - Right-click on ProductivityTracker folder in Xcode
   - Select "Add Files to ProductivityTracker..."
   - Navigate to `/home/user/onscreen/ProductivityTracker`
   - Select the entire `ProductivityTracker` folder
   - **IMPORTANT:**
     - ✅ Check "Copy items if needed" = **NO**
     - ✅ Check "Create groups"
     - ✅ Add to target: ProductivityTracker
   - Click Add

7. **Configure Core Data Model:**
   - Open `ProductivityTracker.xcdatamodeld`
   - Click "+" to add entities

   **Add SessionEntity:**
   - Name: `SessionEntity`
   - Add Attributes (click "+" in Attributes section):
     - `id` (UUID) - uncheck Optional, check Indexed
     - `appName` (String) - check Indexed
     - `bundleID` (String) - check Indexed
     - `windowTitle` (String)
     - `url` (String)
     - `category` (String) - check Indexed
     - `startTime` (Date) - check Indexed
     - `endTime` (Date) - check Indexed
     - `duration` (Double) - uncheck Optional
   - Set Codegen: Manual/None

   **Add RuleEntity:**
   - Name: `RuleEntity`
   - Add Attributes:
     - `id` (UUID) - uncheck Optional, check Indexed
     - `name` (String)
     - `conditionType` (String)
     - `pattern` (String)
     - `category` (String) - check Indexed
     - `priority` (Int16) - uncheck Optional, check Indexed
     - `isEnabled` (Boolean) - uncheck Optional
     - `createdAt` (Date)
   - Set Codegen: Manual/None

8. **Update Info.plist:**
   - Select project in navigator
   - Select ProductivityTracker target
   - Go to "Info" tab
   - Add these keys:
     - `NSAppleEventsUsageDescription`: "Access browser URLs for activity categorization"
     - `NSScreenCaptureUsageDescription`: "Read window titles for accurate tracking"

9. **Set deployment target:**
   - Select project → ProductivityTracker target
   - General tab
   - Minimum Deployments: **macOS 13.0**

10. **Build and Run:**
    - Press ⌘ + B to build
    - Press ⌘ + R to run
    - Grant permissions when prompted

---

## Option 2: Use Provided Script

I've created a script that helps automate some steps. Run:

```bash
cd /home/user/onscreen
chmod +x setup_xcode.sh
./setup_xcode.sh
```

Then follow the remaining manual steps above.

---

## Common Issues & Solutions

### Issue: "Cannot find type 'SessionEntity'"
**Solution:** Make sure Core Data entities have Codegen set to Manual/None and entity files are in the project.

### Issue: "Screen Recording permission"
**Solution:**
- Go to System Settings → Privacy & Security → Screen Recording
- Enable ProductivityTracker
- Restart the app

### Issue: Build errors about missing frameworks
**Solution:** All frameworks are built-in to macOS 13+. Just ensure deployment target is set correctly.

### Issue: "No such module 'Charts'"
**Solution:** Charts is available in macOS 13+. Check your deployment target.

---

## Quick Verification Checklist

After setup, verify:
- ✅ All Swift files appear in Xcode Project Navigator
- ✅ Core Data model has both entities
- ✅ Info.plist has privacy keys
- ✅ Deployment target is macOS 13.0+
- ✅ Project builds without errors (⌘ + B)

---

## Expected First Run Experience

1. **Permission prompts:** Screen Recording and Automation
2. **Empty Dashboard:** Beautiful welcome screen with "Start Tracking" button
3. **Animated background:** Orbiting gradient blobs
4. **Interactive cards:** Hover for 3D tilt effect

Enjoy your beautifully polished productivity tracker! 🚀
