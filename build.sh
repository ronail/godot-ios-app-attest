#!/bin/sh
# Builds app_attest.xcframework (device + simulator, release).
# Usage: GODOT=/path/to/godot-source ./build.sh
# GODOT must be a checkout of the exact engine version you export with, with
# generated headers present (run `scons platform=ios target=template_release`
# there once; you can stop it after the *.gen.h files appear).
set -eu
: "${GODOT:?set GODOT to your Godot source checkout}"
FLAGS="-std=c++17 -fobjc-arc -O2 -DIOS_ENABLED -DUNIX_ENABLED -DNDEBUG -I$GODOT -I$GODOT/platform/ios"
rm -rf build && mkdir -p build/device build/sim

xcrun -sdk iphoneos clang++ $FLAGS -arch arm64 -miphoneos-version-min=12.0 -c src/app_attest.mm -o build/device/app_attest.o
xcrun -sdk iphonesimulator clang++ $FLAGS -arch arm64 -arch x86_64 -mios-simulator-version-min=12.0 -c src/app_attest.mm -o build/sim/app_attest.o
ar rcs build/device/libapp_attest.a build/device/app_attest.o
ar rcs build/sim/libapp_attest.a build/sim/app_attest.o

xcodebuild -create-xcframework \
  -library build/device/libapp_attest.a -headers src \
  -library build/sim/libapp_attest.a -headers src \
  -output build/app_attest.xcframework
echo "Copy build/app_attest.xcframework and AppAttest.gdip into res://ios/plugins/"
