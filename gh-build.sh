#!/bin/bash
set -e

XCODE=$(ls /Applications | grep "Xcode_16" | sort -V | tail -1)
if [ -n "$XCODE" ]; then
  sudo xcode-select -s "/Applications/$XCODE"
fi
xcodebuild -version

xcodebuild archive \
  -project LexiDrill.xcodeproj \
  -scheme LexiDrill \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath LexiDrill.xcarchive \
  CODE_SIGN_STYLE=Manual \
  PROVISIONING_PROFILE="$PROF_UUID" \
  CODE_SIGN_IDENTITY="iPhone Distribution"

PLIST=ExportOptions.plist
/usr/libexec/PlistBuddy -c "Add :method string app-store" $PLIST
/usr/libexec/PlistBuddy -c "Add :teamID string $TEAM_ID" $PLIST
/usr/libexec/PlistBuddy -c "Add :uploadSymbols bool true" $PLIST
/usr/libexec/PlistBuddy -c "Add :compileBitcode bool false" $PLIST
/usr/libexec/PlistBuddy -c "Add :provisioningProfiles dict" $PLIST
/usr/libexec/PlistBuddy \
  -c "Add :provisioningProfiles:com.jirifilipec.mnemoapp string $PROF_UUID" \
  $PLIST

xcodebuild -exportArchive \
  -archivePath LexiDrill.xcarchive \
  -exportPath Export \
  -exportOptionsPlist ExportOptions.plist

xcrun altool --upload-app \
  -f Export/LexiDrill.ipa \
  -t ios \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID" \
  --verbose

security delete-keychain build.keychain || true
rm -f ~/.appstoreconnect/private_keys/AuthKey_*.p8
