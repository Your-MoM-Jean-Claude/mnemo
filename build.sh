#!/bin/bash
  set -e
  PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
  PROFILE_UUID=$(security cms -D -i "$PROFILES_DIR/mnemo.mobileprovision" 2>/dev/null
  | plutil -extract UUID raw -)
  rm -f /tmp/export.plist
  /usr/libexec/PlistBuddy -c "Add :method string app-store" /tmp/export.plist
  /usr/libexec/PlistBuddy -c "Add :teamID string 4SK4LT94PV" /tmp/export.plist
  /usr/libexec/PlistBuddy -c "Add :signingStyle string manual" /tmp/export.plist
  /usr/libexec/PlistBuddy -c "Add :signingCertificate string Apple Distribution"
  /tmp/export.plist
  /usr/libexec/PlistBuddy -c "Add :provisioningProfiles dict" /tmp/export.plist
  /usr/libexec/PlistBuddy -c "Add :provisioningProfiles:com.jirifilipec.mnemoapp
  string $PROFILE_UUID" /tmp/export.plist
  xcodebuild archive -project "LexiDrill.xcodeproj" -scheme "LexiDrill" -configuration
   Release -archivePath /tmp/LexiDrill.xcarchive CODE_SIGN_STYLE=Manual
  CODE_SIGN_IDENTITY="Apple Distribution" PROVISIONING_PROFILE="$PROFILE_UUID"
  DEVELOPMENT_TEAM=4SK4LT94PV
  mkdir -p build/ios/ipa
  xcodebuild -exportArchive -archivePath /tmp/LexiDrill.xcarchive -exportPath
  build/ios/ipa/ -exportOptionsPlist /tmp/export.plist
