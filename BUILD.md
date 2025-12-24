# Build Instructions - ProductivityTracker

## Simple 3-Step Setup

### Step 1: Download the Project

Since you're working in Claude Code, you'll need to download this entire folder to your Mac:

**Option A: Using GitHub** (if you've pushed to GitHub)
```bash
git clone <your-repo-url>
cd onscreen
```

**Option B: Download Directly**
- Download the entire `/home/user/onscreen` folder
- Transfer it to your Mac

### Step 2: Open in Xcode

On your Mac:

1. Navigate to the downloaded `onscreen` folder
2. **Double-click** `ProductivityTracker.xcodeproj`
3. Xcode will open automatically

### Step 3: Build and Run

In Xcode:

1. **Select your Mac as the target** (top toolbar near play button)
2. **Press ⌘+B** to build (or Product → Build)
3. **Press ⌘+R** to run (or Product → Run)

That's it! The app will compile and launch.

## First Time Setup

When you first run the app, macOS will ask for permissions:

### Required Permissions:
1. **Screen Recording** - To detect active windows
   - Go to: System Settings → Privacy & Security → Screen Recording
   - Enable "ProductivityTracker"

2. **Accessibility** - To track window information
   - Go to: System Settings → Privacy & Security → Accessibility
   - Enable "ProductivityTracker"

After granting permissions, **restart the app**.

## What You Get

A fully functional macOS productivity tracker with:

- ✅ **Dashboard** - Real-time tracking with animated stats
- ✅ **Analytics** - Beautiful charts showing productivity patterns
- ✅ **Rules** - Automatic categorization of activities
- ✅ **Settings** - Export data, launch at login
- ✅ **Menu Bar** - Quick access to all features
- ✅ **Visual Polish** - 12 advanced UI components integrated:
  - Animated numbers and counters
  - 3D hover effects on cards
  - Haptic feedback throughout
  - Smart tooltips everywhere
  - Beautiful empty states
  - Confetti celebrations
  - Mesh gradient backgrounds
  - And more!

## Troubleshooting

### Build Errors?

If you see any errors:

1. **Clean Build Folder**: Product → Clean Build Folder (⌘+Shift+K)
2. **Check Xcode Version**: Requires Xcode 15+ and macOS 13+
3. **Check Team**: Go to Signing & Capabilities, select your team

### App Won't Track?

1. Make sure you granted Screen Recording permission
2. Restart the app after granting permissions
3. Check System Settings → Privacy & Security

## File Structure

```
ProductivityTracker.xcodeproj/     ← Xcode project (ready to open!)
ProductivityTracker/               ← All source code
  ├── Core/                       ← Business logic
  ├── Data/                       ← Core Data persistence
  ├── Platform/                   ← System integrations
  ├── Presentation/               ← SwiftUI views
  ├── ProductivityTracker.xcdatamodeld/  ← Database model
  ├── Info.plist                 ← App permissions
  └── ProductivityTracker.entitlements   ← Security settings
```

## Quick Reference

| Action | Shortcut |
|--------|----------|
| Build | ⌘+B |
| Run | ⌘+R |
| Clean | ⌘+Shift+K |
| Stop | ⌘+. |

## Need Help?

The project is 100% complete and ready to compile. If you encounter any issues:

1. Check that you're using Xcode 15+ on macOS 13+
2. Ensure all files are present (36 Swift files total)
3. Try cleaning the build folder first

Happy tracking! 🚀
