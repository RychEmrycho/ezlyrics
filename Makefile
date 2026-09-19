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
	@echo "  make test-coverage - Run tests with code coverage report"
	@echo "  make install  - Build release binary and install to ~/Applications"
	@echo "  make package  - Build the release DMG for local testing"
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

test-coverage:
	swift test --enable-code-coverage --xunit-output junit.xml
	xcrun llvm-cov report \
		-instr-profile=$$(swift build --show-bin-path)/codecov/default.profdata \
		$$(swift build --show-bin-path)/ezlyricsPackageTests.xctest/Contents/MacOS/ezlyricsPackageTests \
		-ignore-filename-regex="\.build|Tests"
	xcrun llvm-cov export -format="lcov" \
		-instr-profile=$$(swift build --show-bin-path)/codecov/default.profdata \
		$$(swift build --show-bin-path)/ezlyricsPackageTests.xctest/Contents/MacOS/ezlyricsPackageTests \
		-ignore-filename-regex="\.build|Tests" > lcov.info

install:
	./install.sh

package:
	./package.sh local_test

clean:
	swift package clean
	rm -rf ezlyrics.app
	rm -f ezlyrics-*.dmg
