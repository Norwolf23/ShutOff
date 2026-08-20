#!/bin/zsh
# Builds ShutOff.app into build/ — icon, binary, bundle, ad-hoc signature.
set -e
cd "$(dirname "$0")"

swift makeicon.swift
sips -z 1024 1024 icon_1024.png >/dev/null   # normalize retina-scaled render
rm -rf AppIcon.iconset && mkdir AppIcon.iconset
for s in 16 32 128 256 512; do
  sips -z $s $s icon_1024.png --out AppIcon.iconset/icon_${s}x${s}.png >/dev/null
  sips -z $((s * 2)) $((s * 2)) icon_1024.png --out AppIcon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns AppIcon.iconset

rm -rf build
APP=build/ShutOff.app
mkdir -p $APP/Contents/MacOS $APP/Contents/Resources
swiftc -O -parse-as-library main.swift -o $APP/Contents/MacOS/ShutOff
cp Info.plist $APP/Contents/
cp AppIcon.icns $APP/Contents/Resources/
codesign --force -s - $APP
echo "Built $APP"
