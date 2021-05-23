#!/bin/bash

# Do not run format on CI
if "$CI"; then
  exit 0
fi

# Do not run format if swiftlint isn't installed
if which swiftformat >/dev/null; then
  echo "Start formatting"
  # swiftlint autocorrect --path .
  swiftformat "FlowCrypt" \
     --rules trailingSpace, blankLinesAtEndOfScope, consecutiveBlankLines, consecutiveSpaces, \
     duplicateImports, initCoderUnavailable, isEmpty, leadingDelimiters, preferKeyPath, redundantBreak, \
     redundantExtensionACL, redundantFileprivate, redundantGet, redundantLet, redundantLetError, \
     redundantNilInit, redundantParens, redundantPattern, redundantVoidReturnType, semicolons, \
     sortedImports, spaceAroundBraces, spaceAroundBrackets, spaceAroundGenerics, spaceInsideBraces, spaceInsideGenerics, \
     strongifiedSelf, trailingClosures, void
else
  echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
  brew install swiftformat
  exit 0
fi

################### RULES https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md
# ASCellNodeBlock - removed due to Opening Brace Spacing Violation when dealing with ASCellNodeBlock
