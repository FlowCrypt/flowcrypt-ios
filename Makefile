.PHONY: all
all: keyboard

.PHONY: kill
kill:
	scripts/clean.sh

.PHONY: keyboard
keyboard: 
	scripts/keyboard.sh
