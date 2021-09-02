#!/bin/bash

set -euxo pipefail # debug + fail when any command fails

if [ -z "${CI:-}" ]; then
  echo "Not on CI - running SwiftFormat"
else
  echo "On CI - skipping SwiftFormat"
  exit 0
fi

# Do not run format if swiftlint isn't installed
if which swiftformat >/dev/null; then
  echo "Start formatting"
  # swiftlint autocorrect --path .
  swiftformat "FlowCrypt", "FlowCryptUITests" \
    --rules trailingSpace \
    --rules blankLinesAtEndOfScope \
    --rules consecutiveBlankLines \
    --rules consecutiveSpaces \
    --rules duplicateImports \
    --rules isEmpty \
    --rules leadingDelimiters \
    --rules redundantBreak \
    --rules redundantExtensionACL \
    --rules redundantFileprivate \
    --rules redundantGet \
    --rules redundantLet \
    --rules redundantLetError \
    --rules redundantNilInit\
    --rules redundantParens \
    --rules redundantPattern \
    --rules redundantVoidReturnType \
    --rules semicolons \
    --rules sortedImports \
    --rules spaceAroundBraces \
    --rules spaceAroundBrackets \
    --rules spaceAroundGenerics \
    --rules spaceInsideBraces \
    --rules spaceInsideGenerics \
    --rules strongifiedSelf \
    --rules trailingClosures \
    --rules void

else
  echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
  brew install swiftformat
  exit 0
fi

################### RULES https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md
# ASCellNodeBlock - removed due to Opening Brace Spacing Violation when dealing with ASCellNodeBlock

# following rules were not available on swiftformat version 0.40.12
#    --rules preferKeyPath \
#    --rules initCoderUnavailable \
