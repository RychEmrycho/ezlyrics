import XCTest
@testable import ezlyrics

final class LyricResolverTests: XCTestCase {
    
    let lines = [
        LyricLine(timestamp: 10.0, text: "Line 1", syllables: nil),
        LyricLine(timestamp: 20.0, text: "Line 2", syllables: nil),
        LyricLine(timestamp: 30.0, text: "Line 3", syllables: nil),
        LyricLine(timestamp: 40.0, text: "Line 4", syllables: nil)
    ]
    
    func testResolveEmptyLines() {
        let resolver = LyricResolver()
        let state = resolver.resolve(effectiveTime: 5.0, lines: [], currentIndex: -1)
        
        XCTAssertNil(state.activeLine)
        XCTAssertNil(state.nextLine)
        XCTAssertEqual(state.activeIndex, -1)
    }
    
    func testResolveBeforeFirstLine() {
        let resolver = LyricResolver()
        let state = resolver.resolve(effectiveTime: 5.0, lines: lines, currentIndex: -1)
        
        XCTAssertNil(state.activeLine)
        XCTAssertEqual(state.nextLine?.text, "Line 1")
        XCTAssertEqual(state.nextNextLine?.text, "Line 2")
        XCTAssertEqual(state.activeIndex, -1)
    }
    
    func testResolveDuringActiveLine() {
        let resolver = LyricResolver()
        let state = resolver.resolve(effectiveTime: 15.0, lines: lines, currentIndex: -1)
        
        XCTAssertEqual(state.activeLine?.text, "Line 1")
        XCTAssertEqual(state.nextLine?.text, "Line 2")
        XCTAssertEqual(state.nextNextLine?.text, "Line 3")
        XCTAssertEqual(state.activeIndex, 0)
    }
    
    func testOptimizationSameLine() {
        let resolver = LyricResolver()
        // If we are at 12.0 and the current index was 0, it should optimize and return 0
        let state = resolver.resolve(effectiveTime: 12.0, lines: lines, currentIndex: 0)
        
        XCTAssertEqual(state.activeLine?.text, "Line 1")
        XCTAssertEqual(state.activeIndex, 0)
    }
    
    func testOptimizationNextLine() {
        let resolver = LyricResolver()
        // If we jump from index 0 to index 1
        let state = resolver.resolve(effectiveTime: 22.0, lines: lines, currentIndex: 0)
        
        XCTAssertEqual(state.activeLine?.text, "Line 2")
        XCTAssertEqual(state.activeIndex, 1)
    }
    
    func testJumpBackwards() {
        let resolver = LyricResolver()
        // We were at index 2 (time 30-40), but scrubbed back to time 15
        let state = resolver.resolve(effectiveTime: 15.0, lines: lines, currentIndex: 2)
        
        XCTAssertEqual(state.activeLine?.text, "Line 1")
        XCTAssertEqual(state.activeIndex, 0)
    }
    
    func testAfterLastLine() {
        let resolver = LyricResolver()
        let state = resolver.resolve(effectiveTime: 45.0, lines: lines, currentIndex: 3)
        
        XCTAssertEqual(state.activeLine?.text, "Line 4")
        XCTAssertNil(state.nextLine)
        XCTAssertNil(state.nextNextLine)
        XCTAssertEqual(state.activeIndex, 3)
    }
    
    func testSilenceDetection() {
        let resolver = LyricResolver(silenceGapThreshold: 5.0, endSilenceThreshold: 8.0)
        // Line 2 ends at 30.0, we are at 26.0 (time elapsed 6s, time to next 4s)
        // silenceGapThreshold is 5.0, so this should trigger silence if both elapsed > 5 and timeToNext > 2
        let state = resolver.resolve(effectiveTime: 26.0, lines: lines, currentIndex: 1)
        
        XCTAssertEqual(state.activeLine?.text, "•••") // Silence
    }
    
    func testEndSilenceDetection() {
        let resolver = LyricResolver(silenceGapThreshold: 5.0, endSilenceThreshold: 8.0)
        // Line 4 is the last line. It starts at 40.0.
        // At 49.0 (elapsed 9s), it should trigger end silence since elapsed > 8.0
        let state = resolver.resolve(effectiveTime: 49.0, lines: lines, currentIndex: 3)
        
        XCTAssertEqual(state.activeLine?.text, "♫") // Silence at the end
    }
}
