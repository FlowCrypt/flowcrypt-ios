.PHONY: all
all: reset keyboard 

.PHONY: reset
kill:
	bundle exec fastlane reset_simulator 

.PHONY: keyboard
keyboard: 
	killall Simulator
	defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false
	chmod +x scripts/keyboard.sh
	scripts/keyboard.sh
