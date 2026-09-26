import Foundation
import SwiftUI

@MainActor
class UserPreferences: ObservableObject {
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
    @AppStorage("funModeBouncingSinger") var funModeBouncingSinger: Bool = false
    @AppStorage("funModeDiscoGradient") var funModeDiscoGradient: Bool = false
    @AppStorage("funModeFloatingNotes") var funModeFloatingNotes: Bool = false
    @AppStorage("funModeConfetti") var funModeConfetti: Bool = false
    @AppStorage("funModeWobblySinger") var funModeWobblySinger: Bool = false
    @AppStorage("funModeNyanCat") var funModeNyanCat: Bool = false
}
