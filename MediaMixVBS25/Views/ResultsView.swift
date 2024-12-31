import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var resultsManager: ResultsManager

    var body: some View {
        List(resultsManager.results, id: \.segmentId) { result in
            HStack {
                Text(result.segmentId)
                Spacer()
                Text("\(result.score, specifier: "%.2f")")
            }
        }
        .navigationTitle("Query Results")
        .padding()
    }
}
