.PHONY: all
all: reset, keyboard 

.PHONY: reset
kill:
	bundle exec fastlane reset_simulator 

.PHONY: keyboard
keyboard: 
	defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false
