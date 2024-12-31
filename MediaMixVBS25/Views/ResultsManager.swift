import SwiftUI

class ResultsManager: ObservableObject {
    @Published var results: [QueryResult] = []
    @Published var showResultsWindow: Bool = false
    
    init() {
            print("ResultsManager initialized") // Confirm initialization
        }
}
