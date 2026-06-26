#!/usr/bin/env bash
# Install the built APK on the first connected device.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
APK=$HERE/build/RootAICLI.apk

if [ ! -f "$APK" ]; then
    echo "APK not built. Run: $HERE/build.sh" >&2
    exit 1
fi

SERIAL=${ANDROID_SERIAL:-$(adb devices | awk '$2=="device" {print $1; exit}')}
if [ -z "$SERIAL" ]; then
    echo "No connected ADB device. Plug in USB or 'adb connect <ip>:5555' first." >&2
    exit 1
fi

echo "Installing Root.AICLI on $SERIAL..."
adb -s "$SERIAL" install -r "$APK"
echo "Done. Launch from app drawer as 'Root.AICLI'."
echo "On first action tap, your root manager will ask for su access. Grant + remember."
