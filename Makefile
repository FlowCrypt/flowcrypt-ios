.PHONY: all
all: reset 

.PHONY: reset
kill:
	bundle exec fastlane reset_simulator 

