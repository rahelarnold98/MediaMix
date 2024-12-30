import SwiftUI
import FereLightSwiftClient

struct QueryResult: Identifiable {
    var segmentId: String
    let score: Double

    // Identifiable requirement
    var id: String { segmentId }
}

struct QuerySystemView: View {
    @State private var selectedDatabase: String = "v3c" // Default database
    @State private var queryText: String = "" // User input for similarity/ASR text
    @State private var results: [QueryResult] = []
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var showResultsWindow: Bool = false // Controls the results window

    private let client = FereLightClient(url: URL(string: "http://localhost:8080")!) // Update host/port as needed

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            // Query Menu
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

            // Loading Indicator
            if isLoading {
                ProgressView("Loading...")
                    .padding()
            }

            // Error Message
            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .sheet(isPresented: $showResultsWindow) {
            ResultsView(results: results)
                .frame(width: 500, height: 300) // Set size for the new results window
        }
    }

    private func performQuery(similarityText: String?, ocrText: String?) {
        isLoading = true
        errorMessage = nil
        results = []

        Task {
            do {
                let queryResults = try await client.query(
                    database: selectedDatabase,
                    similarityText: similarityText,
                    ocrText: ocrText,
                    limit: 10
                )

                // Map the query results and present the results window
                await MainActor.run {
                    self.results = queryResults.map { result in
                        QueryResult(
                            segmentId: result.segmentId,
                            score: result.score
                        )
                    }
                    self.isLoading = false
                    self.showResultsWindow = true // Show the results window
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct ResultsView: View {
    let results: [QueryResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Results")
                .font(.headline)
                .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(results) { result in
                        Text("Segment ID: \(result.segmentId) - Confidence: \(result.score, specifier: "%.2f")")
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding()
    }
}
