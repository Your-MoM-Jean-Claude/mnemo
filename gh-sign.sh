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
echo "$PROFILE_B64" | base64 --decode \
  > "$PROF_DIR/LexiDrill.mobileprovision"

mkdir -p ~/.appstoreconnect/private_keys
echo "$ASC_KEY_B64" | base64 --decode \
  > ~/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8
