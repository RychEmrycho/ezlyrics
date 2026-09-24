# AGENTS.md — ezlyrics

> Comprehensive guide for AI coding assistants working on the ezlyrics codebase.

---

## 1. Project Overview

**ezlyrics** is a native macOS menu-bar application that displays floating, real-time synchronized lyrics for the currently playing song. It auto-detects playback from any media source (Spotify, Apple Music, YouTube in Safari/Chrome, etc.) via Apple's private `MediaRemote` framework, fetches lyrics from the [LRCLIB](https://lrclib.net) API, and renders them as a draggable overlay with karaoke-style wipe animations.

| Attribute | Value |
|-----------|-------|
| Language | Swift 6.0 (strict concurrency) |
| UI Frameworks | SwiftUI + AppKit (hybrid) |
| Build System | Swift Package Manager (no `.xcodeproj`) |
| Min Deployment | macOS 14.0 (Sonoma) |
| Translation Feature | macOS 15.0+ (Sequoia) — requires `Translation` framework |
| Lyrics Provider | [LRCLIB](https://lrclib.net) (free, open API) |
| License | GPLv3 |

The app runs as an **accessory** process (no Dock icon) — all interaction happens through the **menu bar icon** and the **floating overlay window**.

---

## 2. Architecture

The project follows a **Clean Architecture** pattern with clear layer separation. Dependencies point **inward** — outer layers depend on inner layers, never the reverse.

```
┌─────────────────────────────────────────────────┐
│                    App Layer                     │
│         (main.swift, AppCoordinator)             │
│         Composition root — wires everything      │
├─────────────────────────────────────────────────┤
│                 Features Layer                   │
│    Overlay │ MenuBar │ Playback │ Settings │     │
│                  Localization                    │
│         SwiftUI views + ViewModels               │
├─────────────────────────────────────────────────┤
│                 Domain Layer                     │
│      Models │ Protocols │ Services               │
│    Pure business logic, no framework imports     │
├─────────────────────────────────────────────────┤
│                  Data Layer                      │
│   Network │ Cache │ Repository │ MediaRemote     │
│     Concrete implementations of protocols        │
├─────────────────────────────────────────────────┤
│  Infrastructure │ DesignSystem │ Scripts          │
│   Cross-cutting concerns & bundled resources     │
└─────────────────────────────────────────────────┘
```

### Key Architectural Patterns

- **Coordinator Pattern** — `AppCoordinator` is the single composition root. It instantiates all concrete types and wires dependencies. No other class creates its own dependencies.
- **Dependency Inversion** — The Domain layer defines protocols (`LyricsRepository`, `NowPlayingProvider`, `LyricsCacheProtocol`). The Data layer provides concrete implementations. Features depend only on protocols.
- **Combine Reactivity** — Track changes flow through `@Published` properties and Combine pipelines: `MediaRemoteSystem` → `NowPlayingMonitor` → `PlaybackViewModel` → SwiftUI views.
- **Strategy Pattern** — Lyrics recommendation uses pluggable `RecommendationRule` implementations (`SyncedLyricsRule`, `DurationRule`, `TitleMatchRule`, `ArtistMatchRule`) scored and ranked by `LyricsRecommendationEngine`.
- **Actor Concurrency** — `LyricsCache` is a Swift `actor` for thread-safe two-tier caching. All UI-bound types are annotated `@MainActor`.

---

## 3. Directory Structure

```
Sources/
├── App/                           # Entry point & composition root
│   ├── main.swift                 # NSApplication setup, AppDelegate, edit menu
│   └── AppCoordinator.swift       # Composition root — wires all layers together
│
├── Domain/                        # Pure business logic (no framework dependencies)
│   ├── Models/
│   │   ├── Track.swift            # Now-playing track metadata
│   │   ├── LyricLine.swift        # Single lyric line + syllable-level timestamps
│   │   ├── ParsedLyrics.swift     # Parsed lyrics container (synced or plain)
│   │   ├── FetchResult.swift      # Fetch result + recommendation rules
│   │   └── SearchResult.swift     # Provider-agnostic search result DTO
│   ├── Protocols/
│   │   ├── LyricsRepository.swift       # Abstract lyrics fetch/search operations
│   │   ├── NowPlayingProvider.swift      # Abstract media monitoring
│   │   └── LyricsCacheProtocol.swift     # Abstract two-tier cache
│   └── Services/
│       ├── LyricsParser.swift            # LRC format parser + language detection
│       ├── LyricResolver.swift           # Real-time active line resolution (binary search)
│       ├── LyricsRecommendationEngine.swift  # Best-match scoring engine
│       ├── Romanizer.swift               # CJK/non-Latin → Latin transliteration
│       └── TrackMetadataParser.swift      # Normalizes raw artist/title metadata
│
├── Data/                          # Concrete implementations
│   ├── Network/
│   │   ├── LRCLIBClient.swift           # HTTP client for lrclib.net API
│   │   ├── LRCLIBResponse.swift         # API response DTO (Codable)
│   │   └── LRCLIBResponse+SearchResult.swift  # DTO → domain model mapping
│   ├── Cache/
│   │   └── LyricsCache.swift            # Actor-based two-tier cache (NSCache + disk JSON)
│   ├── Repository/
│   │   └── LyricsRepositoryImpl.swift   # Concrete LyricsRepository (cache → API → fallback search)
│   └── MediaRemote/
│       └── MediaRemoteSystem.swift      # NowPlayingProvider via subprocess helper script
│
├── Features/                      # UI feature modules
│   ├── Overlay/
│   │   ├── FloatingHUDWindowController.swift  # NSPanel-based floating window
│   │   ├── LyricsOverlayView.swift            # Main overlay SwiftUI view (karaoke wipe)
│   │   └── FloatingLyricLineView.swift        # Single animated lyric line
│   ├── MenuBar/
│   │   ├── MenuBarController.swift      # NSStatusItem setup
│   │   ├── MenuBarView.swift            # Root menu popover view
│   │   ├── MenuBarViewModel.swift       # Menu bar state + search logic
│   │   ├── MenuBarLyricsViewer.swift    # Full lyrics scrollable viewer
│   │   ├── MenuBarSearchSection.swift   # Manual search UI
│   │   ├── MenuBarSyncOffsetView.swift  # Timing offset ±100ms stepper
│   │   ├── MenuBarNowPlayingHeader.swift # Now-playing info header
│   │   ├── MenuRows.swift              # Reusable menu row components
│   │   ├── SearchResultRow.swift        # Search result list item
│   │   └── ScrollMonitorState.swift     # Auto-scroll state management
│   ├── Playback/
│   │   ├── PlaybackViewModel.swift      # Core playback state, syncing timer, line resolution
│   │   └── NowPlayingMonitor.swift      # Bridges NowPlayingProvider → @Published track
│   ├── Settings/
│   │   ├── SettingsView.swift           # Tab-based settings window
│   │   ├── SettingsWindowController.swift # NSWindow host for settings
│   │   ├── AppearanceTab.swift          # Font, colors, layout settings
│   │   ├── TranslationTab.swift         # Translation & romanization settings
│   │   ├── AboutTab.swift               # App info & version
│   │   └── UserPreferences.swift        # @AppStorage-backed preferences (singleton)
│   └── Localization/
│       ├── BatchTranslationWrapper.swift    # macOS 15+ Translation framework wrapper
│       ├── TranslatableItem.swift           # Protocol for translatable content
│       └── TranslationConfigurator.swift    # Translation session config builder
│
├── Infrastructure/                # Cross-cutting concerns
│   └── AppLogger.swift            # os.Logger instances by category
│
└── DesignSystem/                  # Shared UI utilities
    └── Color+Hex.swift            # SwiftUI Color ↔ hex string conversion

Tests/
└── ezlyricsTests/                 # Unit tests (Swift Testing framework)
    ├── LRCLIBClientTests.swift
    ├── LRCLIBResponseSearchResultTests.swift
    ├── LyricResolverTests.swift
    ├── LyricsCacheTests.swift
    ├── LyricsParserTests.swift
    ├── LyricsRecommendationEngineTests.swift
    ├── LyricsRepositoryImplTests.swift
    ├── PlaybackViewModelSyncTests.swift
    ├── PlaybackViewModelTests.swift
    ├── RomanizerTests.swift
    └── TrackMetadataParserTests.swift
```

---

## 4. Key Abstractions

### Domain Protocols

These three protocols define the boundary between the Domain/Features layers and the Data layer. **All new data sources must implement these protocols** — never import concrete data types in Domain or Features code.

#### `LyricsRepository`
```swift
protocol LyricsRepository: Sendable {
    func fetchBestLyrics(for track: Track) async -> FetchResult
    func searchLyrics(query: String) async throws -> [SearchResult]
    func applyOverride(_ result: SearchResult, for track: Track) async -> ParsedLyrics
}
```
- **Implementation**: `LyricsRepositoryImpl` — tries cache first, then LRCLIB `/get`, then falls back to LRCLIB `/search` with recommendation scoring.

#### `NowPlayingProvider`
```swift
@MainActor
protocol NowPlayingProvider: AnyObject {
    var onTrackChanged: ((Track?) -> Void)? { get set }
    func start()
    func stop()
}
```
- **Implementation**: `MediaRemoteSystem` — launches a hardcoded Swift script as a subprocess, parses `||`-delimited stdout lines.

#### `LyricsCacheProtocol`
```swift
protocol LyricsCacheProtocol: Sendable {
    func getCachedLyrics(artist: String, title: String) async -> ParsedLyrics?
    func cache(lyrics: ParsedLyrics, artist: String, title: String) async
}
```
- **Implementation**: `LyricsCache` (Swift actor) — Tier 1: in-memory `NSCache`, Tier 2: JSON files in `~/Library/Application Support/ezlyrics/Lyrics/`.

---

## 5. Data Flow

### Track Detection → Lyrics Overlay

```
MediaRemoteSystem's Swift Subprocess (polls every 1s)
        │ stdout: "artist||title||duration||elapsed||rate"
        ▼
MediaRemoteSystem (parses pipe-delimited output)
        │ calls onTrackChanged(Track?)
        ▼
NowPlayingMonitor (deduplicates: filters same-song updates, detects scrub >2s)
        │ publishes @Published currentTrack
        ▼
AppCoordinator (Combine sink)
        │ forwards to PlaybackViewModel.onTrackChanged()
        │ manages HUD visibility (show/hide/auto-hide)
        ▼
PlaybackViewModel
        │ 1. Fetches lyrics via LyricsRepository
        │ 2. Starts 50ms sync timer (Timer @ 0.05s interval)
        │ 3. LyricResolver binary-searches active line by effectiveTime
        │ 4. Publishes @Published activeLine, nextLine, nextNextLine
        ▼
LyricsOverlayView (SwiftUI)
        │ Renders karaoke wipe animation from activeLine
        ▼
FloatingHUDWindowController (NSPanel, always-on-top, click-through)
```

### Lyrics Fetching Strategy (in `LyricsRepositoryImpl`)

```
1. Check LyricsCache (memory → disk)
   └─ HIT → return cached ParsedLyrics

2. Try LRCLIB /get endpoint (exact match by artist + title + duration)
   └─ SUCCESS → parse, cache, return
   └─ FAILURE (404 / network error) ↓

3. Fallback: LRCLIB /search endpoint (by title only)
   └─ Score results via LyricsRecommendationEngine
   └─ Apply recommendation rules (synced? duration? title match? artist match?)
   └─ Return best match or empty result
```

---

## 6. Concurrency Model

This project uses **Swift 6 strict concurrency**. Follow these rules:

- **`@MainActor`** — All UI-bound types (`ViewModels`, `Controllers`, `AppCoordinator`, `NowPlayingMonitor`, `UserPreferences`) must be annotated `@MainActor`. SwiftUI views are implicitly `@MainActor`.
- **`Sendable`** — All domain protocols are marked `Sendable`. Value types (`struct`) in `Domain/Models/` are implicitly `Sendable`. Ensure any new protocol crossing actor boundaries is `Sendable`.
- **Swift Actors** — `LyricsCache` is a Swift `actor` for thread-safe mutable state. Use actors for any new shared mutable state rather than locks or dispatch queues.
- **`nonisolated`** — Methods on `@MainActor` classes that don't touch isolated state should be marked `nonisolated` (see `LyricsRepositoryImpl` methods).
- **`@preconcurrency import`** — Used for frameworks that haven't adopted Sendable yet (e.g., `@preconcurrency import Translation`).
- **No `DispatchQueue` for new code** — Use structured concurrency (`Task`, `async/await`) instead. The one exception is `MediaRemoteSystem.parseLine()` which uses `DispatchQueue.main.async` to bridge from a C callback context.

---

## 7. Coding Conventions

### General Style
- **Naming**: Swift API Design Guidelines — types are `UpperCamelCase`, properties/methods are `lowerCamelCase`.
- **File Naming**: One primary type per file, file name matches the type name (e.g., `LyricsParser.swift` contains `struct LyricsParser`).
- **Extensions**: Placed in `TypeName+Extension.swift` files (e.g., `Color+Hex.swift`, `LRCLIBResponse+SearchResult.swift`).
- **Access Control**: Default to `internal`. Use `private` for implementation details. Use `public` only for types/methods that are genuinely part of the module's API (rare in this single-module project).
- **Constants**: No magic numbers — use named constants or configurable init parameters (see `LyricResolver` thresholds).

### SwiftLint
The project uses SwiftLint with the following configuration (`.swiftlint.yml`):

**Disabled rules**: `line_length`, `trailing_whitespace`, `trailing_comma`, `identifier_name`, `function_body_length`, `type_body_length`

**Opt-in rules**: `empty_count`, `missing_docs`

**Analyzer rules**: `explicit_self`

**Severity overrides**: `force_cast: warning`, `force_try: warning`

Run the linter with `make lint` (auto-installs SwiftLint via Homebrew if missing).

### Import Ordering
Follow this order:
1. `Foundation` / `Cocoa`
2. Apple frameworks (`SwiftUI`, `Combine`, `NaturalLanguage`, `Translation`, `os`)
3. (No third-party dependencies currently)

### Documentation
- All protocols must have doc comments (`///`).
- All public/internal types should have a brief doc comment explaining their purpose.
- The `missing_docs` SwiftLint rule is opt-in — strive to document all declarations.

### Logging
Use `AppLogger` (backed by `os.Logger`) with category-specific loggers:
- `AppLogger.shared` — general
- `AppLogger.mediaRemote` — media detection
- `AppLogger.lyrics` — lyrics fetching/parsing
- `AppLogger.ui` — UI events

**Do not use `print()` for logging** in production code. The only exception is the subprocess script in `MediaRemoteSystem.swift` which uses `print()` + `fflush(stdout)` to communicate via stdout pipe.

---

## 8. Testing

### Framework
Tests use **Swift Testing** (not XCTest). Test files are located in `Tests/ezlyricsTests/`.

### Test Coverage
| Area | Test File | What It Covers |
|------|-----------|----------------|
| Network | `LRCLIBClientTests.swift` | HTTP client with mock `URLSessionProtocol` |
| DTO Mapping | `LRCLIBResponseSearchResultTests.swift` | Response → SearchResult conversion |
| Lyric Resolution | `LyricResolverTests.swift` | Binary search, silence detection, edge cases |
| Caching | `LyricsCacheTests.swift` | Memory + disk cache round-trip |
| Parsing | `LyricsParserTests.swift` | LRC format parsing, plain text fallback |
| Recommendation | `LyricsRecommendationEngineTests.swift` | Rule scoring + best-match selection |
| Repository | `LyricsRepositoryImplTests.swift` | Full fetch flow: cache → API → fallback |
| Playback Sync | `PlaybackViewModelSyncTests.swift` | Timer-based line syncing |
| Playback | `PlaybackViewModelTests.swift` | Track change handling, offset, state |
| Romanization | `RomanizerTests.swift` | CJK → Latin transliteration |
| Metadata | `TrackMetadataParserTests.swift` | YouTube title parsing, junk tag stripping |

### Testability Patterns
- **Protocol-based mocking**: `URLSessionProtocol` allows injecting mock network responses. `StringTransliterator` protocol allows testing `Romanizer` without system transliterator.
- **Dependency injection**: All major classes accept dependencies via `init` — see `LRCLIBClient(session:)`, `LyricsCache(cacheDirectory:)`, `PlaybackViewModel(resolver:, repository:)`.
- **When adding new code**: If it has side effects or external dependencies, define a protocol and inject the dependency. Write tests for all business logic in `Domain/Services/` and data operations in `Data/`.

### Running Tests
```bash
make test                # Run all tests
make test-coverage       # Run tests + generate lcov.info coverage report
```

---

## 9. Build & Run

### Prerequisites
- **Xcode 16+** (or Command Line Tools) — required for the macOS 15 `Translation` framework SDK
- **Homebrew** (optional, for SwiftLint auto-install)

### Makefile Targets

| Command | Description |
|---------|-------------|
| `make build` | Debug build (`swift build`) |
| `make release` | Release build (`swift build -c release`) |
| `make run` | Run locally (`swift run`) |
| `make lint` | Run SwiftLint (auto-installs if needed) |
| `make test` | Run unit tests |
| `make test-coverage` | Tests + llvm-cov coverage report → `lcov.info` |
| `make install` | Build release + install to `~/Applications` via `install.sh` |
| `make package` | Build release DMG via `package.sh` |
| `make clean` | Remove `.build/`, `*.app`, `*.dmg` |
| `make setup` | Install SwiftLint via Homebrew |

### Local Development Workflow
```bash
make build          # Verify compilation
make lint           # Check code style
make test           # Run tests
make run            # Launch the app locally
```

---

## 10. CI/CD

### Main Pipeline (`main.yml`)
Triggered on **push to `main`** and **pull requests to `main`**.

```
Checkout → Show Toolchain → Lint → Build → Test + Coverage → Upload to Codecov → Semantic Release
```

- Runs on `macos-15` GitHub-hosted runners
- Coverage uploaded to **Codecov** (requires `CODECOV_TOKEN` secret)
- Test results uploaded as JUnit XML
- **Semantic Release** runs only on push to `main` (not on PRs) — creates version tags based on Conventional Commits

### Tag Pipeline (`tag.yml`)
Triggered on **version tags** (`v*`).

```
Checkout → Extract Version → Build + Package DMG → Upload to GitHub Release
```

- Runs `package.sh` to create `ezlyrics-vX.X.X.dmg`
- Uploads DMG as a GitHub Release asset

### Semantic Release
Configured via `.releaserc.json`:
- Analyzes commits using Conventional Commits
- Generates release notes
- Creates GitHub releases with changelogs
- **Branches**: `main` only

---

## 11. Special Notes

### MediaRemote Private Framework
- `MediaRemote.framework` is a **private Apple framework** located at `/System/Library/PrivateFrameworks/`.
- The app does **not** link it directly at the Swift module level. Instead, `MediaRemoteSystem` runs a hardcoded Swift script as a **separate subprocess** invoked via `/usr/bin/swift`, loading the framework dynamically at runtime via `CFBundleCreate` + `CFBundleGetFunctionPointerForName`.
- `Package.swift` includes linker flags (`-F/System/Library/PrivateFrameworks -framework MediaRemote`) for the main target, though the actual MediaRemote interaction happens in the subprocess.
- **This approach means the app cannot be distributed via the Mac App Store** (private API usage). Distribution is via signed DMGs on GitHub Releases.

### Translation Availability
- The `Translation` framework is only available on **macOS 15.0+**.
- All translation-related code is gated behind `@available(macOS 15.0, *)`.
- The `BatchTranslationWrapper` uses `@ViewBuilder` to gracefully degrade on macOS 14 (returns `self` unmodified).
- When adding translation features, always use `if #available(macOS 15.0, *)` guards.

### App Lifecycle
- The app uses `NSApplication.shared.run()` directly — **not** SwiftUI's `@main App` or `NSApplicationMain`.
- `AppDelegate` creates the `AppCoordinator` in `applicationDidFinishLaunching`.
- The app is set as `.accessory` — no Dock icon, only menu bar presence.
- A manual `NSMenu` is constructed in `main.swift` to provide Edit menu keyboard shortcuts (Cmd+C/V/X/A) in text fields.

### UserPreferences
- `UserPreferences` is a `@MainActor` singleton using `@AppStorage` for persistence.
- All preference keys are string-based `@AppStorage` properties — no custom `Codable` storage.
- Changes are observed via `NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)` in `AppCoordinator`.

### Cache Strategy
- **Tier 1**: In-memory `NSCache<NSString, NSData>` — fast lookups, evicted by OS under memory pressure.
- **Tier 2**: Disk-backed JSON files at `~/Library/Application Support/ezlyrics/Lyrics/` — persistent across launches.
- Cache keys are hash-based: `"\(artist.hashValue)_\(title.hashValue).json"`.

---

## 12. Adding New Features

### New Domain Model
→ Add to `Sources/Domain/Models/`. Make it a `struct` conforming to `Equatable` (and `Codable` if cached/serialized). Add tests.

### New Domain Service (pure logic)
→ Add to `Sources/Domain/Services/`. Keep it a stateless `struct` with `static` methods or injected dependencies. No framework imports beyond `Foundation`. Add comprehensive tests.

### New Data Source / Provider
→ Define a protocol in `Sources/Domain/Protocols/`. Implement it in `Sources/Data/` under the appropriate subdirectory. Wire it in `AppCoordinator.init()`. Use protocol-based mocking in tests.

### New Feature Module (UI)
→ Create a new directory under `Sources/Features/`. Structure it as:
```
Features/NewFeature/
├── NewFeatureView.swift          # SwiftUI view
├── NewFeatureViewModel.swift     # @MainActor ObservableObject
└── (supporting views/controllers)
```
Wire the ViewModel in `AppCoordinator` and connect it to the relevant data flows.

### New Preference
→ Add an `@AppStorage` property to `UserPreferences`. If the preference needs to trigger side effects, observe it in `AppCoordinator`'s `UserDefaults.didChangeNotification` sink.

### New Recommendation Rule
→ Implement the `RecommendationRule` protocol and add it to `LyricsRecommendationEngine.rules`. Add tests for the new rule's scoring logic.

### New Logger Category
→ Add a new `static let` to `AppLogger` with a descriptive category string.
