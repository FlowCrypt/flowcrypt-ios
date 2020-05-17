#!/bin/bash

# Do not run format on CI
if [ "$USER" = 'jenkins' ]; then
  exit 0
fi

format() {
    swiftlint autocorrect --path "$1"
    swiftformat "$1" \
        --rules trailingSpace,indent,redundantSelf,redundantReturn,spaceAroundOperators,braces,elseOnSameLine,blankLinesAroundMark \
        --indent 4 \
        --operatorfunc no-space \
        --swiftversion 5
}

# Check if script run with an argument
[ -z "$1" ] || { format "$1"; exit 0; }

# Loop through all changed files with swift extension
echo "Formating changed swift files..."
git ls-files --other --modified --exclude-standard | grep "\.swift$" | while read filename; do
    [ -f "$filename" ] && format "$filename"
done
