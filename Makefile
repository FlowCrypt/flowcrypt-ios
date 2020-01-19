.PHONY: all
all: reset keyboard 

.PHONY: reset
kill:
	bundle exec fastlane reset_simulator 

.PHONY: keyboard
keyboard: 
	chmod +x scripts/keyboard.sh
	scripts/keyboard.sh
