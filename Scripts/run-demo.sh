#!/bin/sh
set -eu

package_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$package_dir"
swift build --product FilterablePickerDemo
bin_dir=$(swift build --show-bin-path)
app_dir="$package_dir/.build/FilterablePickerDemo.app"
mkdir -p "$app_dir/Contents/MacOS"
cp "$bin_dir/FilterablePickerDemo" "$app_dir/Contents/MacOS/FilterablePickerDemo"
cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key><string>FilterablePickerDemo</string>
    <key>CFBundleIdentifier</key><string>local.FilterablePickerDemo</string>
    <key>CFBundleName</key><string>Filterable Picker Demo</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app_dir"
open "$app_dir"
