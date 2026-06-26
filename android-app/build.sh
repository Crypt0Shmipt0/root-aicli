#!/usr/bin/env bash
# Gradle-free APK build pipeline.
# Steps: generate launcher icons, compile resources with aapt2, generate
# R.java, compile Java with javac, dex with d8, package, align, sign.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
BUILD=$HERE/build
PKG=dev.rootaicli
NAME=RootAICLI

: "${ANDROID_HOME:=$HOME/Library/Android/sdk}"
: "${JAVA_HOME:=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

BT=$ANDROID_HOME/build-tools/34.0.0
PLATFORM=$ANDROID_HOME/platforms/android-34
ANDROID_JAR=$PLATFORM/android.jar
AAPT2=$BT/aapt2
D8=$BT/d8
APKSIGNER=$BT/apksigner
ZIPALIGN=$BT/zipalign

if [ ! -x "$AAPT2" ] || [ ! -x "$D8" ] || [ ! -x "$APKSIGNER" ]; then
    echo "ERROR: missing Android build-tools. See README install instructions." >&2
    exit 1
fi

export PATH=$JAVA_HOME/bin:$PATH

mkdir -p "$BUILD"

echo "[1/7] Generating launcher icons..."
"$HERE/tools/make-icon.sh" "$HERE/res"

echo "[2/7] Compiling resources..."
rm -rf "$BUILD/compiled"
mkdir -p "$BUILD/compiled"
"$AAPT2" compile --dir "$HERE/res" -o "$BUILD/compiled.zip"

echo "[3/7] Linking resources + generating R.java..."
mkdir -p "$BUILD/gen"
"$AAPT2" link \
    -I "$ANDROID_JAR" \
    --manifest "$HERE/AndroidManifest.xml" \
    -o "$BUILD/app-base.apk" \
    --java "$BUILD/gen" \
    "$BUILD/compiled.zip"

echo "[4/7] Compiling Java..."
rm -rf "$BUILD/classes"
mkdir -p "$BUILD/classes"
# Quote each source path (handles iCloud / paths with spaces) when feeding the
# argfile to javac.
find "$HERE/src" "$BUILD/gen" -name '*.java' -print0 \
    | xargs -0 -I{} printf '"%s"\n' "{}" > "$BUILD/sources.txt"
javac --release 11 \
    -classpath "$ANDROID_JAR" \
    -d "$BUILD/classes" \
    @"$BUILD/sources.txt"

echo "[5/7] Dexing..."
( cd "$BUILD/classes" && jar cf "$BUILD/classes.jar" . )
"$D8" --output "$BUILD/" "$BUILD/classes.jar"

echo "[6/7] Packaging APK..."
cp "$BUILD/app-base.apk" "$BUILD/app-unaligned.apk"
( cd "$BUILD" && zip -uj app-unaligned.apk classes.dex )

echo "[7/7] Aligning + signing..."
"$ZIPALIGN" -f -p 4 "$BUILD/app-unaligned.apk" "$BUILD/$NAME.apk"
if [ ! -f "$BUILD/debug.keystore" ]; then
    echo "  generating debug keystore..."
    "$JAVA_HOME/bin/keytool" -genkey -v -keystore "$BUILD/debug.keystore" \
        -storepass android -keypass android -alias androiddebugkey \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "CN=Android Debug, O=Android, C=US"
fi
"$APKSIGNER" sign --ks "$BUILD/debug.keystore" \
    --ks-pass pass:android --key-pass pass:android \
    "$BUILD/$NAME.apk"
"$APKSIGNER" verify "$BUILD/$NAME.apk" && echo "  signature OK"

echo
echo "Done."
echo "APK: $BUILD/$NAME.apk"
ls -lh "$BUILD/$NAME.apk"
echo
echo "To install on a connected device:"
echo "  adb install -r '$BUILD/$NAME.apk'"
echo "Or:"
echo "  $HERE/install-apk.sh"
