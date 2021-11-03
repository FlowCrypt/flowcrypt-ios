#!/bin/bash

set -euxo pipefail # debug + fail when any command fails

npm i -g sharp-cli

sizes=(20 29 40 50 57 58 60 72 76 80 87 100 114 120 144 152 167 180 1024)

for size in "${sizes[@]}"
do
  echo "Generating $size.png"
  sharp -i ./Scripts/flowcrypt-ios-svg.svg -o "./FlowCrypt/Assets.xcassets/Appicon.appiconset/$size.png" resize $size $size -- flatten "#ffffff"
  sharp -i ./Scripts/flowcrypt-ios-enterprise-svg.svg -o "./FlowCrypt/Assets.xcassets/Appicon-Enterprise.appiconset/$size.png" resize $size $size -- flatten "#ffffff"
  sharp -i ./Scripts/flowcrypt-ios-debug-svg.svg -o "./FlowCrypt/Assets.xcassets/Appicon-Debug.appiconset/$size.png" resize $size $size -- flatten "#ffffff"
done

