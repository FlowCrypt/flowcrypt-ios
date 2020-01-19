/usr/libexec/PlistBuddy -c "Print :DevicePreferences" ~/Library/Preferences/com.apple.iphonesimulator.plist | perl -lne 'print $1 if /^    (\S*) =/' | while read -r a; do /usr/libexec/PlistBuddy -c "Set :DevicePreferences:$a:ConnectHardwareKeyboard
false" ~/Library/Preferences/com.apple.iphonesimulator.plist || /usr/libexec/PlistBuddy -c  "Add :DevicePreferences:$a:ConnectHardwareKeyboard
bool false" ~/Library/Preferences/com.apple.iphonesimulator.plist; done
