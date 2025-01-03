import SwiftUI
import FereLightSwiftClient

import SwiftUI

struct QuerySystemView: View {
    @EnvironmentObject var resultsManager: ResultsManager
    @State private var selectedDatabase: String = "v3c"
    @State private var queryText: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @Environment(\.openWindow) var openWindow

    private var client: FereLightClient {
        FereLightClient(url: URL(string: ConfigurationManager.shared.apiBaseURL)!)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Select Query")
                .font(.headline)

            Picker("Query Menu", selection: $selectedDatabase) {
                Text("V3C").tag("v3c")
                Text("MVK").tag("mvk")
                Text("LHE").tag("lhe")
            }
            .pickerStyle(SegmentedPickerStyle())

            // Text input field
            TextField("Enter your query...", text: $queryText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical)

            // Query Buttons
            HStack {
                Button("Text Query") {
                    performQuery(similarityText: queryText, ocrText: nil)
                }
                .buttonStyle(DefaultButtonStyle())
                .frame(maxWidth: .infinity)
                .disabled(queryText.isEmpty)

                Button("OCR Query") {
                    performQuery(similarityText: nil, ocrText: queryText)
                }
                .buttonStyle(DefaultButtonStyle())
                .frame(maxWidth: .infinity)
                .disabled(queryText.isEmpty)

                Button("ASR Query") {
                    performQuery(similarityText: queryText, ocrText: nil)
                }
                .buttonStyle(DefaultButtonStyle())
                .frame(maxWidth: .infinity)
                .disabled(queryText.isEmpty)
            }
            .frame(height: 44)
            .padding(.horizontal)

            if isLoading {
                ProgressView("Loading...")
            }

            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }

    private func performQuery(similarityText: String?, ocrText: String?) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let queryResults = try await client.query(
                    database: selectedDatabase,
                    similarityText: similarityText,
                    ocrText: ocrText,
                    limit: 1000
                )

                await MainActor.run {
                    resultsManager.database = selectedDatabase
                    resultsManager.results = queryResults.map { QueryResult(segmentId: $0.segmentId, score: $0.score) }
                    isLoading = false

                    // Trigger the opening of the Results Window
                    openWindow(id: "resultsWindow")

                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
