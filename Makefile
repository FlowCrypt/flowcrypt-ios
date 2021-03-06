.PHONY: all
all: ui_tests

dependencies:
	bundle config set path 'vendor/bundle'
	bundle install

ui_tests: dependencies
	bundle exec fastlane test_ui --verbose

format:
	Scripts/format.sh

snapshots: dependencies
	brew update && brew install imagemagick
	bundle exec fastlane snapshot
	cd fastlane/screenshots
	fastlane frameit

