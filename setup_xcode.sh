#!/bin/bash

# Xcode Project Setup Helper Script
# This script helps prepare the project structure for Xcode

set -e

echo "🚀 ProductivityTracker - Xcode Setup Helper"
echo "==========================================="
echo ""

# Check if we're in the right directory
if [ ! -d "ProductivityTracker" ]; then
    echo "❌ Error: ProductivityTracker directory not found"
    echo "   Please run this script from /home/user/onscreen"
    exit 1
fi

echo "✅ Found ProductivityTracker directory"

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "⚠️  Xcode command line tools not found"
    echo "   Please install Xcode from the App Store first"
    exit 1
fi

echo "✅ Xcode detected"
echo ""

# Display file count
SWIFT_FILES=$(find ProductivityTracker -name "*.swift" -type f | wc -l | tr -d ' ')
echo "📊 Project Statistics:"
echo "   Swift files: $SWIFT_FILES"
echo "   Components: $(ls ProductivityTracker/Presentation/Components/*.swift 2>/dev/null | wc -l | tr -d ' ')"
echo ""

# Check if project already exists
if [ -d "ProductivityTracker.xcodeproj" ]; then
    echo "⚠️  Xcode project already exists: ProductivityTracker.xcodeproj"
    read -p "   Do you want to open it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open ProductivityTracker.xcodeproj
        exit 0
    else
        exit 0
    fi
fi

echo "📝 Next Steps:"
echo ""
echo "1. Create New Xcode Project:"
echo "   • Open Xcode"
echo "   • File → New → Project"
echo "   • Choose: macOS → App"
echo "   • Interface: SwiftUI, Language: Swift"
echo "   • Enable 'Use Core Data'"
echo "   • Save to: $(pwd)"
echo ""

echo "2. Add Existing Files:"
echo "   • Right-click project in Xcode"
echo "   • 'Add Files to ProductivityTracker...'"
echo "   • Select the ProductivityTracker folder"
echo "   • Uncheck 'Copy items if needed'"
echo "   • Check 'Create groups'"
echo ""

echo "3. Configure Core Data:"
echo "   • Open ProductivityTracker.xcdatamodeld"
echo "   • Add SessionEntity (9 attributes)"
echo "   • Add RuleEntity (7 attributes)"
echo "   • Set both to Codegen: Manual/None"
echo ""

echo "4. Update Info.plist:"
echo "   • Add NSAppleEventsUsageDescription"
echo "   • Add NSScreenCaptureUsageDescription"
echo ""

echo "5. Build & Run:"
echo "   • Press ⌘ + B to build"
echo "   • Press ⌘ + R to run"
echo ""

echo "📖 For detailed instructions, see: CREATE_XCODE_PROJECT.md"
echo ""

read -p "Press Enter to open Xcode..."
open -a Xcode .

echo ""
echo "✅ Done! Follow the steps above to complete setup."
echo ""
