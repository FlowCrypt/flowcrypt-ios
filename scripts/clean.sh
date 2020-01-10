#!/bin/bash

boot_if_needed() {	
  bootedDevices=$(xcrun simctl list devices | grep "(Booted)" | wc -l)
  if [[ $bootedDevices -eq 0 ]]; then
      open -a "Simulator"
      echo "Start Simulator"
      sleep 3
  else
      echo "Simulator already running" 
  fi
  
}

remove_app_from_device() {
      echo "Remove app from simulator if installed"
      xcrun simctl uninstall booted com.flowcrypt.ios.debug
      xcrun simctl uninstall booted com.flowcrypt.ios
      xcrun simctl uninstall booted com.flowcrypt.ios.testflight
}

boot_if_needed remove_app_from_device 
