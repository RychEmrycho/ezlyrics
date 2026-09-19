import XCTest
@testable import ezlyrics

final class MockStringTransliterator: StringTransliterator {
    var toLatinHandler: ((String) -> String?)?
    var stripCombiningMarksHandler: ((String) -> String?)?
    
    func toLatin(_ text: String) -> String? {
        return toLatinHandler?(text) ?? text
    }
    
    func stripCombiningMarks(_ text: String) -> String? {
        return stripCombiningMarksHandler?(text) ?? text
    }
}

final class RomanizerTests: XCTestCase {
    
    var mockTransliterator: MockStringTransliterator!
    var sut: Romanizer!
    
    override func setUp() {
        super.setUp()
        mockTransliterator = MockStringTransliterator()
        sut = Romanizer(transliterator: mockTransliterator)
    }
    
    func testNoChangeForLatin() {
        mockTransliterator.toLatinHandler = { _ in "Hello World" }
        mockTransliterator.stripCombiningMarksHandler = { _ in "Hello World" }
        
        XCTAssertNil(sut.romanize("Hello World"))
    }
    
    func testRomanizeJapanese() {
        mockTransliterator.toLatinHandler = { _ in "arigatou" }
        mockTransliterator.stripCombiningMarksHandler = { _ in "arigatou" }
        
        XCTAssertEqual(sut.romanize("ありがとう"), "arigatou")
    }
    
    func testDiacriticsAreStripped() {
        mockTransliterator.toLatinHandler = { _ in "nǐ hǎo" }
        mockTransliterator.stripCombiningMarksHandler = { _ in "ni hao" }
        
        XCTAssertEqual(sut.romanize("你好"), "ni hao")
    }
}
