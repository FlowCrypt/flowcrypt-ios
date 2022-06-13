sleep 15

xcrun simctl list devices available 15.5

IOS_SIM_UDID=$(xcrun simctl list devices available 15.5 | grep "iPhone 13 (" | grep -E -o -i "([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})")
SIMULATOR_PATH='/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/Contents/MacOS/Simulator'

echo "Found UUID of iPhone 13 - ${IOS_SIM_UDID}"

open -a "$SIMULATOR_PATH" --args -CurrentDeviceUDID $IOS_SIM_UDID

function booted_sim_ct() {
  echo `xcrun simctl list devices 15.5 | grep Booted | wc -l | sed -e 's/ //g'`
}

while [ `booted_sim_ct` -lt 1 ]
do
  sleep 1
done

sleep 20

echo 'BOOTED'
xcrun simctl list devices booted 15.5 
xcrun simctl keychain $IOS_SIM_UDID add-root-cert ./appium/api-mocks/mock-ssl-cert/cert.pem
xcrun simctl list devices available 15.5

sleep 5