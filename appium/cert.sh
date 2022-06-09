IOS_SIM_UDID=$(xcrun simctl list devices | grep "iPhone 13" | grep -E -o -i "([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})");
SIMULATOR_PATH='/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/Contents/MacOS/Simulator'

open -a "$SIMULATOR_PATH" --args -CurrentDeviceUDID $IOS_SIM_UDID

function booted_sim_ct() {
  echo `xcrun simctl list | grep Booted | wc -l | sed -e 's/ //g'`
}

while [ `booted_sim_ct` -lt 1 ]
do
  sleep 1
done

sleep 10

xcrun simctl keychain "iPhone 13" add-root-cert ./appium/api-mocks/mock-ssl-cert/cert.pem