.PHONY: setup build release run lint test install clean help

# Default target
help:
	@echo "Available commands:"
	@echo "  make setup    - Install dependencies like SwiftLint (requires Homebrew)"
	@echo "  make build    - Build the project in debug mode"
	@echo "  make release  - Build the project in release mode"
	@echo "  make run      - Run the project locally"
	@echo "  make lint     - Run SwiftLint to check code style"
	@echo "  make test     - Run Swift tests"
	@echo "  make install  - Build release binary and install to ~/Applications"
	@echo "  make clean    - Clean build artifacts"

build:
	swift build

setup:
	@if ! command -v swiftlint >/dev/null; then \
		if command -v brew >/dev/null; then \
			echo "Installing SwiftLint via Homebrew..."; \
			brew install swiftlint; \
		else \
			echo "Homebrew is not installed. Please install it first from https://brew.sh/"; \
			exit 1; \
		fi \
	fi

release:
	swift build -c release

run:
	swift run

lint: setup
	swiftlint

test:
	swift test

install:
	./install.sh

clean:
	swift package clean
	rm -rf ezlyrics.app
