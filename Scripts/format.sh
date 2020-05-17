#!/bin/bash

# Do not run format on CI
if "$CI"; then
  exit 0
fi

# Do not run format if swiftlint isn't installed
if which swiftformat >/dev/null; then
  echo "Start formating"
  swiftlint autocorrect --path .
  swiftformat . \
     --rules trailingSpace \
     --swiftversion 5
else
  echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
  brew install swiftformat
  exit 0
fi
