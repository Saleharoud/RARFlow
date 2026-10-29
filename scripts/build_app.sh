#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/RARFlow.app"

echo "=== 1. Generating App Icon ==="
mkdir -p "$BUILD_DIR"
swift "$SCRIPT_DIR/generate_icon.swift"
iconutil -c icns "$BUILD_DIR/AppIcon.iconset" -o "$BUILD_DIR/AppIcon.icns"

echo "=== 2. Building Release Binary ==="
cd "$PROJECT_DIR"
swift build -c release

RELEASE_BIN="$PROJECT_DIR/.build/release/RARFlow"
if [ ! -f "$RELEASE_BIN" ]; then
    echo "Error: Release binary not found at $RELEASE_BIN"
    exit 1
fi

echo "=== 3. Creating App Bundle Structure ==="
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$APP_DIR/Contents/Helpers"

# Copy main executable
cp "$RELEASE_BIN" "$APP_DIR/Contents/MacOS/RARFlow"
chmod +x "$APP_DIR/Contents/MacOS/RARFlow"

# Copy icon and resources
cp "$BUILD_DIR/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$SCRIPT_DIR/install_finder_services.sh" "$APP_DIR/Contents/Resources/install_finder_services.sh"
chmod +x "$APP_DIR/Contents/Resources/install_finder_services.sh"

echo "=== 4. Bundling Helper Engines ==="
if [ -d "$PROJECT_DIR/Helpers" ]; then
    cp -R "$PROJECT_DIR/Helpers/"* "$APP_DIR/Contents/Helpers/"
    chmod +x "$APP_DIR/Contents/Helpers/"*
    echo "  -> Bundled helpers:"
    ls -1 "$APP_DIR/Contents/Helpers"
else
    echo "  [Warning] Helpers directory not found"
fi

echo "=== 5. Generating Info.plist with NSServices ==="
cat > "$APP_DIR/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>RARFlow</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.rarflow.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>RARFlow</string>
    <key>CFBundleDisplayName</key>
    <string>RARFlow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 RARFlow. All rights reserved.</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>RAR Archive</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>rar</string>
                <string>r00</string>
                <string>cbr</string>
            </array>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.rarlab.rar-archive</string>
                <string>public.rar</string>
            </array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>7-Zip Archive</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>7z</string>
                <string>cb7</string>
            </array>
            <key>LSItemContentTypes</key>
            <array>
                <string>org.7-zip.7-zip-archive</string>
            </array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>ZIP Archive</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>zip</string>
                <string>zipx</string>
                <string>cbz</string>
            </array>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.zip-archive</string>
            </array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>TAR Archive</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>tar</string>
                <string>gz</string>
                <string>bz2</string>
                <string>xz</string>
                <string>tgz</string>
                <string>tbz2</string>
                <string>txz</string>
            </array>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.tar-archive</string>
            </array>
        </dict>
    </array>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>Extract using RARFlow</string>
            </dict>
            <key>NSMessage</key>
            <string>extractSelection</string>
            <key>NSPortName</key>
            <string>RARFlow</string>
            <key>NSRequiredContext</key>
            <dict>
                <key>NSTextContent</key>
                <string>FilePath</string>
            </dict>
            <key>NSSendFileTypes</key>
            <array>
                <string>public.item</string>
            </array>
        </dict>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>Compress using RARFlow</string>
            </dict>
            <key>NSMessage</key>
            <string>compressSelection</string>
            <key>NSPortName</key>
            <string>RARFlow</string>
            <key>NSRequiredContext</key>
            <dict>
                <key>NSTextContent</key>
                <string>FilePath</string>
            </dict>
            <key>NSSendFileTypes</key>
            <array>
                <string>public.item</string>
            </array>
        </dict>
    </array>
    <key>UTImportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>com.rarlab.rar-archive</string>
            <key>UTTypeDescription</key>
            <string>RAR Archive</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.data</string>
                <string>public.archive</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>rar</string>
                    <string>r00</string>
                    <string>cbr</string>
                </array>
                <key>public.mime-type</key>
                <string>application/x-rar-compressed</string>
            </dict>
        </dict>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>org.7-zip.7-zip-archive</string>
            <key>UTTypeDescription</key>
            <string>7-Zip Archive</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.data</string>
                <string>public.archive</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>7z</string>
                    <string>cb7</string>
                </array>
                <key>public.mime-type</key>
                <string>application/x-7z-compressed</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>
EOF

echo "=== 6. Code Signing Bundle ==="
codesign --force --deep --sign - "$APP_DIR"
codesign -vvv "$APP_DIR"

echo "=== 7. Registering with macOS LaunchServices ==="
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [ -x "$LSREGISTER" ]; then
    "$LSREGISTER" -f "$APP_DIR"
    echo "  -> RARFlow registered as file handler for .rar, .7z, .zip"
fi

echo "=== 8. Installing Finder Right-Click Quick Actions ==="
"$SCRIPT_DIR/install_finder_services.sh"

echo "=== SUCCESS! RARFlow.app successfully built at: $APP_DIR ==="
