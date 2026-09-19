import Testing
@testable import ezlyrics

@Suite struct LyricResolverTests {
    
    let lines = [
        LyricLine(timestamp: 10.0, text: "Line 1", syllables: nil),
        LyricLine(timestamp: 20.0, text: "Line 2", syllables: nil),
        LyricLine(timestamp: 30.0, text: "Line 3", syllables: nil),
        LyricLine(timestamp: 40.0, text: "Line 4", syllables: nil)
    ]
    
    @Test func ResolveEmptyLines() {
        let resolver = LyricResolver()
        let state = resolver.resolve(effectiveTime: 5.0, lines: [], currentIndex: -1)
        
        #expect(state.activeLine == nil)
        #expect(state.nextLine == nil)
        #expect(state.activeIndex == -1)
    }
    
    @Test func ResolveBeforeFirstLine() {
        let resolver = LyricResolver()
        let state = resolver.resolve(effectiveTime: 5.0, lines: lines, currentIndex: -1)
        
        #expect(state.activeLine == nil)
        #expect(state.nextLine?.text == "Line 1")
        #expect(state.nextNextLine?.text == "Line 2")
        #expect(state.activeIndex == -1)
    }
    
    @Test func ResolveDuringActiveLine() {
        let resolver = LyricResolver()
        let state = resolver.resolve(effectiveTime: 15.0, lines: lines, currentIndex: -1)
        
        #expect(state.activeLine?.text == "Line 1")
        #expect(state.nextLine?.text == "Line 2")
        #expect(state.nextNextLine?.text == "Line 3")
        #expect(state.activeIndex == 0)
    }
    
    @Test func OptimizationSameLine() {
        let resolver = LyricResolver()
        // If we are at 12.0 and the current index was 0, it should optimize and return 0
        let state = resolver.resolve(effectiveTime: 12.0, lines: lines, currentIndex: 0)
        
        #expect(state.activeLine?.text == "Line 1")
        #expect(state.activeIndex == 0)
    }
    
    @Test func OptimizationNextLine() {
        let resolver = LyricResolver()
        // If we jump from index 0 to index 1
        let state = resolver.resolve(effectiveTime: 22.0, lines: lines, currentIndex: 0)
        
        #expect(state.activeLine?.text == "Line 2")
        #expect(state.activeIndex == 1)
    }
    
    @Test func JumpBackwards() {
        let resolver = LyricResolver()
        // We were at index 2 (time 30-40), but scrubbed back to time 15
        let state = resolver.resolve(effectiveTime: 15.0, lines: lines, currentIndex: 2)
        
        #expect(state.activeLine?.text == "Line 1")
        #expect(state.activeIndex == 0)
    }
    
    @Test func AfterLastLine() {
        let resolver = LyricResolver()
        let state = resolver.resolve(effectiveTime: 45.0, lines: lines, currentIndex: 3)
        
        #expect(state.activeLine?.text == "Line 4")
        #expect(state.nextLine == nil)
        #expect(state.nextNextLine == nil)
        #expect(state.activeIndex == 3)
    }
    
    @Test func SilenceDetection() {
        let resolver = LyricResolver(silenceGapThreshold: 5.0, endSilenceThreshold: 8.0)
        // Line 2 ends at 30.0, we are at 26.0 (time elapsed 6s, time to next 4s)
        // silenceGapThreshold is 5.0, so this should trigger silence if both elapsed > 5 and timeToNext > 2
        let state = resolver.resolve(effectiveTime: 26.0, lines: lines, currentIndex: 1)
        
        #expect(state.activeLine?.text == "•••") // Silence
    }
    
    @Test func EndSilenceDetection() {
        let resolver = LyricResolver(silenceGapThreshold: 5.0, endSilenceThreshold: 8.0)
        // Line 4 is the last line. It starts at 40.0.
        // At 49.0 (elapsed 9s), it should trigger end silence since elapsed > 8.0
        let state = resolver.resolve(effectiveTime: 49.0, lines: lines, currentIndex: 3)
        
        #expect(state.activeLine?.text == "♫") // Silence at the end
    }
}
