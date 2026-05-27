#!/bin/bash
set -e

security create-keychain -p "$KC_PASS" build.keychain
security default-keychain -s build.keychain
security unlock-keychain -p "$KC_PASS" build.keychain
security set-keychain-settings -t 3600 -l build.keychain

echo "$CERT_B64" | base64 --decode > cert.p12
security import cert.p12 \
  -k build.keychain \
  -P "$CERT_PASS" \
  -T /usr/bin/codesign
security set-key-partition-list \
  -S apple-tool:,apple: \
  -s -k "$KC_PASS" build.keychain
rm cert.p12

PROF_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROF_DIR"
echo "$PROFILE_B64" | base64 --decode > /tmp/mnemo.mobileprovision
security cms -D -i /tmp/mnemo.mobileprovision 2>/dev/null > /tmp/mnemo.plist
PROF_UUID=$(/usr/libexec/PlistBuddy -c "Print :UUID" /tmp/mnemo.plist)
echo "Profile UUID: $PROF_UUID"
cp /tmp/mnemo.mobileprovision "$PROF_DIR/$PROF_UUID.mobileprovision"
rm /tmp/mnemo.mobileprovision /tmp/mnemo.plist
echo "PROF_UUID=$PROF_UUID" >> "$GITHUB_ENV"

mkdir -p ~/.appstoreconnect/private_keys
echo "$ASC_KEY_B64" | base64 --decode \
  > ~/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8
