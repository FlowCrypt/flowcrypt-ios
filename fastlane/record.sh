record() {
    echo "Start recording"
    xcrun simctl io booted recordVideo tests.mov 
}

boot_device_if_needed() {
  deviceName=$1
  bootedDevices=$(xcrun simctl list devices | grep "(Booted)" | grep "$deviceName" | wc -l)
  if [[ $bootedDevices -eq 0 ]]; then
    xcrun simctl boot "$deviceName"
  else
    echo "$deviceName is already booted"
  fi
}

run_tests() {
  deviceName=$1
  xcodebuild -workspace FlowCrypt.xcworkspace -scheme FlowCryptUITests 	-destination "platform=iOS Simulator,name=$deviceName"	CODE_SIGNING_ALLOWED="NO" test | xcpretty
}

defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool NO
open -a Simulator
cd ..
rm -rf tests.mov
deviceName="iPhone 11 Pro Max"
boot_device_if_needed "$deviceName"
# rm -rf ~/Library/Developer/Xcode/DerivedData
# xcodebuild clean -scheme NU.nl-UITests -workspace Beta.xcworkspace

# Start recording and kill recording as soon as tests are done
record & run_tests "$deviceName"; kill -INT `pgrep simctl`

