# tsl-janet Makefile
#
# Targets:
#   make            Build dist/tsl (same as `make build`)
#   make deps       Install Janet dependencies (spork, http) via jpm
#   make test       Run the test suite via jpm
#   make install    Copy dist/tsl to $(PREFIX)/$(BIN_NAME)
#   make uninstall  Remove $(PREFIX)/$(BIN_NAME)
#   make clean      Remove build/ and dist/
#   make help       Show this list

JPM      ?= jpm
PREFIX   ?= $(HOME)/.local/bin
BIN_NAME ?= sl
DIST     := dist/tsl
SOURCES  := project.janet $(wildcard src/*.janet)

.PHONY: all build deps test install uninstall clean help

all: build

build: $(DIST)

$(DIST): $(SOURCES)
	@echo "Building binary..."
	@rm -rf build
	$(JPM) build
	@mkdir -p dist
	@mv build/tsl $(DIST)
	@rm -rf build
	@echo "Build complete. Binary is in $(DIST)"

deps:
	$(JPM) deps

test:
	$(JPM) test

install: $(DIST)
	@mkdir -p $(PREFIX)
	@echo "Installing $(DIST) to $(PREFIX)/$(BIN_NAME)..."
	@cp $(DIST) $(PREFIX)/$(BIN_NAME)
	@chmod +x $(PREFIX)/$(BIN_NAME)
	@if command -v $(BIN_NAME) >/dev/null 2>&1; then \
		echo "Installation successful. Run '$(BIN_NAME) --help' to get started."; \
	else \
		echo "Installed, but $(PREFIX) is not in your PATH."; \
		echo "Add this to your shell profile (~/.zshrc, ~/.bashrc, etc.):"; \
		echo "  export PATH=\"$(PREFIX):\$$PATH\""; \
	fi

uninstall:
	@rm -f $(PREFIX)/$(BIN_NAME)
	@echo "Removed $(PREFIX)/$(BIN_NAME)"

clean:
	@rm -rf build dist
	@echo "Cleaned build/ and dist/"

help:
	@sed -n '3,11p' $(MAKEFILE_LIST)
