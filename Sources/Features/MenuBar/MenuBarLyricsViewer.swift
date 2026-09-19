import SwiftUI

struct MenuBarLyricsViewer: View {
    @ObservedObject var playbackVM: PlaybackViewModel
    let lyrics: ParsedLyrics
    @ObservedObject var scrollState: ScrollMonitorState
    @ObservedObject private var settings = UserPreferences.shared
    
    @State private var isAutoScrollingPlain = false
    @State private var plainScrollSpeedLevel: Int = 0
    @State private var currentPlainLineIndex: Int = 0
    @State private var autoScrollTask: Task<Void, Never>?
    @State private var translatedLines: [UUID: String] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ScrollViewReader { proxy in
                HStack {
                    Text("Full Lyrics:")
                        .font(.headline)
                    Spacer()
                    
                    if lyrics.isSynced {
                        Button(action: {
                            scrollState.isAutoFollowing = true
                            if let activeId = playbackVM.activeLine?.id {
                                withAnimation {
                                    proxy.scrollTo(activeId, anchor: .center)
                                }
                            }
                        }) {
                            Image(systemName: scrollState.isAutoFollowing ? "location.fill" : "location")
                                .foregroundColor(scrollState.isAutoFollowing ? .accentColor : .primary)
                        }
                        .buttonStyle(.plain)
                        .help(scrollState.isAutoFollowing ? "Following active line" : "Follow active line")
                        .padding(.trailing, 4)
                    }
                    
                    if !lyrics.isSynced {
                        Button(action: {
                            toggleAutoScroll(proxy: proxy, lines: lyrics.lines)
                        }) {
                            Image(systemName: isAutoScrollingPlain ? "pause.fill" : "play.fill")
                                .foregroundColor(isAutoScrollingPlain ? .accentColor : .primary)
                        }
                        .buttonStyle(.plain)
                        .help(isAutoScrollingPlain ? "Pause auto-scroll" : "Start auto-scroll")
                        
                        Stepper(value: $plainScrollSpeedLevel, in: 0...10, step: 1) {
                            Text(plainScrollSpeedLevel == 0 ? "Speed: Off" : "Speed: \(plainScrollSpeedLevel)")
                                .font(.caption)
                        }
                        .frame(width: 80)
                        .padding(.trailing, 4)
                    }
                    
                    if settings.enableTranslation {
                        Picker("", selection: $settings.translationSource) {
                            Text("Auto").tag("auto")
                            Text("JA").tag("ja")
                            Text("KO").tag("ko")
                            Text("ZH").tag("zh")
                            Text("ES").tag("es")
                            Text("FR").tag("fr")
                            Text("PT").tag("pt")
                            Text("DE").tag("de")
                            Text("IT").tag("it")
                            Text("RU").tag("ru")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 70)
                        .help("Translation source language")
                    }
                }
                .padding(.top, 4)
                
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(lyrics.lines) { line in
                            Button(action: {
                                if lyrics.isSynced {
                                    syncToLine(line)
                                } else {
                                    if let idx = lyrics.lines.firstIndex(where: { $0.id == line.id }) {
                                        currentPlainLineIndex = idx
                                        withAnimation {
                                            proxy.scrollTo(line.id, anchor: .center)
                                        }
                                    }
                                }
                            }) {
                                MenuBarLyricLineRow(
                                    line: line,
                                    lyrics: lyrics,
                                    playbackVM: playbackVM,
                                    settings: settings,
                                    isLineActive: isLineActive(lyrics: lyrics, line: line),
                                    translatedText: translatedLines[line.id]
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .onHover { scrollState.isHoveringLyrics = $0 }
                .frame(minHeight: 200, maxHeight: 300)
                .onChange(of: playbackVM.activeLine?.id) { _, newId in
                    if scrollState.isAutoFollowing, let newId = newId {
                        withAnimation {
                            proxy.scrollTo(newId, anchor: .center)
                        }
                    }
                }
            }
        }
        .onChange(of: playbackVM.currentTrack) { _, _ in
            isAutoScrollingPlain = false
            autoScrollTask?.cancel()
            autoScrollTask = nil
            currentPlainLineIndex = 0
        }
        .applyBatchTranslation(
            items: lyrics.lines.filter(\.isTranslatable),
            isEnabled: settings.enableTranslation && settings.translationDisplayMode != "overlayOnly",
            sourceLanguage: settings.translationSource,
            targetLanguage: settings.translationTarget,
            detectedLanguage: lyrics.detectedLanguage,
            translatedLines: $translatedLines
        )
    }
    
    private func syncToLine(_ line: LyricLine) {
        if let track = playbackVM.currentTrack {
            var currentElapsed = track.elapsedTime
            if track.isPlaying {
                let timeSinceLastUpdate = Date().timeIntervalSinceReferenceDate - track.lastUpdatedTime
                currentElapsed += timeSinceLastUpdate
            }
            playbackVM.userOffset = line.timestamp - currentElapsed
        }
    }
    
    private var waitTimeForScroll: Double {
        if plainScrollSpeedLevel == 0 {
            return .infinity
        }
        let times = [6.0, 5.0, 4.0, 3.5, 3.0, 2.5, 2.0, 1.5, 1.0, 0.5]
        let idx = max(0, min(times.count - 1, plainScrollSpeedLevel - 1))
        return times[idx]
    }
    
    private func isLineActive(lyrics: ParsedLyrics, line: LyricLine) -> Bool {
        if lyrics.isSynced {
            return playbackVM.activeLine?.id == line.id
        } else {
            return isAutoScrollingPlain && lyrics.lines.firstIndex(where: { $0.id == line.id }) == currentPlainLineIndex
        }
    }
    
    private func toggleAutoScroll(proxy: ScrollViewProxy, lines: [LyricLine]) {
        if isAutoScrollingPlain {
            isAutoScrollingPlain = false
            autoScrollTask?.cancel()
            autoScrollTask = nil
        } else {
            isAutoScrollingPlain = true
            autoScrollTask = Task {
                var accumulated: Double = 0
                let step: Double = 0.1
                while !Task.isCancelled && currentPlainLineIndex < lines.count - 1 {
                    try? await Task.sleep(nanoseconds: UInt64(step * 1_000_000_000))
                    accumulated += step
                    let waitTime = waitTimeForScroll
                    if accumulated >= waitTime {
                        accumulated = 0
                        currentPlainLineIndex += 1
                        let nextId = lines[currentPlainLineIndex].id
                        await MainActor.run {
                            withAnimation(.easeInOut) {
                                proxy.scrollTo(nextId, anchor: .center)
                            }
                        }
                    }
                }
                await MainActor.run {
                    isAutoScrollingPlain = false
                }
            }
        }
    }
}

private struct MenuBarLyricLineRow: View {
    let line: LyricLine
    let lyrics: ParsedLyrics
    @ObservedObject var playbackVM: PlaybackViewModel
    @ObservedObject var settings: UserPreferences
    let isLineActive: Bool
    let translatedText: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if settings.enableRomanization && settings.romanizationDisplayMode != "overlayOnly", let romanized = Romanizer.romanize(line.text) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if lyrics.isSynced {
                        Image(systemName: "waveform")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(playbackVM.activeLine?.id == line.id ? .accentColor : .secondary)
                    } else if isLineActive {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                    
                    if settings.showTimestampsInMenu && lyrics.isSynced {
                        Text(formatTimestamp(line.timestamp))
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(romanized.isEmpty ? "♫" : romanized)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(isLineActive ? .accentColor : .primary)
                }
                
                Text(line.text)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.secondary)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if lyrics.isSynced {
                    } else if isLineActive {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                    if settings.showTimestampsInMenu && lyrics.isSynced {
                        Text(formatTimestamp(line.timestamp))
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Text(line.text.isEmpty ? "♫" : line.text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(isLineActive ? .accentColor : .primary)
                }
            }
            
            if settings.enableTranslation && settings.translationDisplayMode != "overlayOnly", let translated = translatedText, !translated.isEmpty {
                HStack(alignment: .top, spacing: 3) {
                    Image(systemName: "translate")
                        .font(.system(size: 9))
                        .padding(.top, 1)
                    Text(translated)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
    
    private func formatTimestamp(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        let ms = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "[%02d:%02d.%02d]", mins, secs, ms)
    }
}
