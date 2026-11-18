PREFIX ?= $(HOME)/.local
BIN := aerospace-ffm

.PHONY: build test install uninstall clean

build:
	swift build -c release

test:
	swift test

install: build
	install -d $(PREFIX)/bin
	install -m 755 .build/release/$(BIN) $(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)

clean:
	swift package clean
