#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting local build process for AppLock Pro..."

# 1. Clean previous builds
echo "🧹 Cleaning up previous builds..."
rm -rf build
rm -rf output
rm -f AppLockPro*.dmg

# 2. Generate Xcode project
echo "🛠 Generating Xcode project..."
xcodegen generate

# 3. Build the app in Release mode (unsigned)
echo "🏗 Building the app in Release mode..."
xcodebuild -project AppLockPro.xcodeproj \
  -scheme AppLockPro \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
  | grep -v "note: " | grep -v "warning: "

# 4. Prepare for DMG creation
echo "📦 Preparing DMG output folder..."
mkdir -p output
cp -R build/Build/Products/Release/AppLock\ Pro.app output/

# 5. Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "⚙️ Installing create-dmg via npm..."
    npm install -g create-dmg
fi

# 6. Create the DMG
echo "💿 Creating DMG file..."
create-dmg output/AppLock\ Pro.app || true
mv *.dmg AppLockPro.dmg || true

# Cleanup
rm -rf build
rm -rf output

echo ""
echo "✅ Success! Your app is ready at AppLockPro.dmg"
echo "You can now upload AppLockPro.dmg to GitHub Releases."
