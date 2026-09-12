import Foundation
import SwiftUI

class SettingsManager: ObservableObject, @unchecked Sendable {
    static let shared = SettingsManager()
    
    @AppStorage("fontSize") var fontSize: Double = 24
    @AppStorage("textColorHex") var textColorHex: String = "#FFFFFF"
    @AppStorage("showBackground") var showBackground: Bool = true
    @AppStorage("backgroundOpacity") var backgroundOpacity: Double = 0.5
    @AppStorage("enableTranslation") var enableTranslation: Bool = false
    @AppStorage("typography") var typography: String = "rounded"
    @AppStorage("alignment") var alignment: String = "center"
    @AppStorage("lineLayout") var lineLayout: String = "two"
}
