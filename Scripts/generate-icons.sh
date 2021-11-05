#!/bin/bash

set -euxo pipefail # debug + fail when any command fails

sizes=(20 29 40 50 57 58 60 72 76 80 87 100 114 120 144 152 167 180 1024)

for size in "${sizes[@]}"
do
  # Default
  rsvg-convert -w $size -h $size --background-color white ./asset-sources/icons/flowcrypt-ios-svg.svg > ./FlowCrypt/Assets.xcassets/Appicon.appiconset/$size.png
  # Enterprise
  rsvg-convert -w $size -h $size --background-color white ./asset-sources/icons/flowcrypt-ios-enterprise-svg.svg > ./FlowCrypt/Assets.xcassets/Appicon-Enterprise.appiconset/$size.png
  # Debug
  rsvg-convert -w $size -h $size --background-color white ./asset-sources/icons/flowcrypt-ios-debug-svg.svg > ./FlowCrypt/Assets.xcassets/Appicon-Debug.appiconset/$size.png
done

