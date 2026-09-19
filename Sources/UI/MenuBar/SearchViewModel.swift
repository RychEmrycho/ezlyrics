import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var lastAutoSearchQuery: String = ""
    @Published var autoSearchTrigger: UUID = UUID()
    @Published var recommendedResponse: LRCLIBResponse?
}
