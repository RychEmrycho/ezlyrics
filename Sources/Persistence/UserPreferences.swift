import Foundation
import SwiftUI

class UserPreferences: ObservableObject, @unchecked Sendable {
    static let shared = UserPreferences()
    
    @AppStorage("fontSize") var fontSize: Double = 24
    @AppStorage("textColorHex") var textColorHex: String = "#FFFFFF"
    @AppStorage("isAppEnabled") var isAppEnabled: Bool = true
    @AppStorage("showOverlay") var showOverlay: Bool = true
    @AppStorage("showBackground") var showBackground: Bool = true
    @AppStorage("backgroundColorHex") var backgroundColorHex: String = "#000000"
    @AppStorage("backgroundOpacity") var backgroundOpacity: Double = 0.5
    @AppStorage("enableTranslation") var enableTranslation: Bool = false
    @AppStorage("translationDisplayMode") var translationDisplayMode: String = "both"
    @AppStorage("enableRomanization") var enableRomanization: Bool = false
    @AppStorage("romanizationDisplayMode") var romanizationDisplayMode: String = "both"
    @AppStorage("translationSource") var translationSource: String = "auto"
    @AppStorage("translationTarget") var translationTarget: String = "en"
    @AppStorage("typography") var typography: String = "rounded"
    @AppStorage("alignment") var alignment: String = "center"
    @AppStorage("lineLayout") var lineLayout: String = "two"
    @AppStorage("showTimestampsInMenu") var showTimestampsInMenu: Bool = false
}
