#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${1:-}"

if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR" ]]; then
  echo "Usage: ./scripts/install_telebirr_sdks.sh /path/to/TelebirrSDKFolder"
  exit 64
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_LIBS="$ROOT_DIR/android/libs"
ANDROID_MAVEN="$ROOT_DIR/android/libs-maven/com/telebirr/sdk"
IOS_FRAMEWORKS="$ROOT_DIR/ios/Frameworks"

mkdir -p "$ANDROID_LIBS" "$ANDROID_MAVEN" "$IOS_FRAMEWORKS"

copy_if_found() {
  local pattern="$1"
  local destination="$2"
  local match
  match="$(find "$SOURCE_DIR" -name "$pattern" -print -quit)"
  if [[ -n "$match" ]]; then
    cp -R "$match" "$destination"
    echo "Copied $pattern"
  else
    echo "Skipped $pattern: not found"
  fi
}

copy_if_found "EthiopiaPaySdkModule-uat-release.aar" "$ANDROID_LIBS/"
copy_if_found "EthiopiaPaySdkModule-prod-release.aar" "$ANDROID_LIBS/"
copy_if_found "EthiopiaPaySDK.framework" "$IOS_FRAMEWORKS/"

make_maven_artifact() {
  local env_name="$1"
  local artifact_id="$2"
  local aar_name="$3"
  local artifact_dir="$ANDROID_MAVEN/$artifact_id/1.0.0"
  local aar_path="$ANDROID_LIBS/$aar_name"

  if [[ ! -f "$aar_path" ]]; then
    echo "Skipped local Maven artifact for $env_name: $aar_name not found"
    return
  fi

  mkdir -p "$artifact_dir"
  cp "$aar_path" "$artifact_dir/$artifact_id-1.0.0.aar"
  cat > "$artifact_dir/$artifact_id-1.0.0.pom" <<POM
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.telebirr.sdk</groupId>
  <artifactId>$artifact_id</artifactId>
  <version>1.0.0</version>
  <packaging>aar</packaging>
</project>
POM
  echo "Created local Maven artifact for $env_name"
}

make_maven_artifact "UAT" "ethiopia-pay-sdk-uat" "EthiopiaPaySdkModule-uat-release.aar"
make_maven_artifact "production" "ethiopia-pay-sdk-prod" "EthiopiaPaySdkModule-prod-release.aar"

echo "Telebirr SDK setup complete."
