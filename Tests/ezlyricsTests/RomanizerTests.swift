import Testing
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

@Suite struct RomanizerTests {
    
    var mockTransliterator: MockStringTransliterator
    var sut: Romanizer
    
    init() {
        mockTransliterator = MockStringTransliterator()
        sut = Romanizer(transliterator: mockTransliterator)
    }
    
    @Test func noChangeForLatin() {
        mockTransliterator.toLatinHandler = { _ in "Hello World" }
        mockTransliterator.stripCombiningMarksHandler = { _ in "Hello World" }
        
        #expect(sut.romanize("Hello World") == nil)
    }
    
    @Test func romanizeJapanese() {
        mockTransliterator.toLatinHandler = { _ in "arigatou" }
        mockTransliterator.stripCombiningMarksHandler = { _ in "arigatou" }
        
        #expect(sut.romanize("ありがとう") == "arigatou")
    }
    
    @Test func diacriticsAreStripped() {
        mockTransliterator.toLatinHandler = { _ in "nǐ hǎo" }
        mockTransliterator.stripCombiningMarksHandler = { _ in "ni hao" }
        
        #expect(sut.romanize("你好") == "ni hao")
    }
}
