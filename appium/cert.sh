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

sleep 20

xcrun simctl keychain booted add-root-cert ./appium/api-mocks/mock-ssl-cert/cert.pem

sleep 5

xcrun simctl shutdown $IOS_SIM_UDID