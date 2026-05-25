#!/bin/bash
  set -e
  keychain initialize
  echo "$CM_CERTIFICATE" | base64 --decode > /tmp/cert.p12
  KEYCHAIN=$(security default-keychain | xargs)
  security import /tmp/cert.p12 -k "$KEYCHAIN" -P "$CM_CERTIFICATE_PASSWORD" -T
  /usr/bin/codesign -A
  PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
  mkdir -p "$PROFILES_DIR"
  echo "$PROVISIONING_PROFILE" | base64 --decode >
  "$PROFILES_DIR/mnemo.mobileprovision"
  PROFILE_UUID=$(security cms -D -i "$PROFILES_DIR/mnemo.mobileprovision" 2>/dev/null
  | plutil -extract UUID raw -)
  echo "Profile UUID: $PROFILE_UUID"
