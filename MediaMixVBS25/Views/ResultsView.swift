import SwiftUI
import FereLightSwiftClient

struct ResultsView: View {
    @EnvironmentObject var resultsManager: ResultsManager
    @State private var segmentInfos: [String: (objectId: String, segmentNumber: Int, segmentStart: Int, segmentEnd: Int, segmentStartAbs: Double, segmentEndAbs: Double)] = [:]
    @State private var isLoading = true

    private var client: FereLightClient {
        FereLightClient(url: URL(string: ConfigurationManager.shared.apiBaseURL)!)
    }

    var body: some View {
        ScrollView { // Enables scrolling
            LazyVStack(alignment: .leading) { // Efficient layout for dynamic content
                if isLoading {
                    ProgressView("Loading data...")
                        .padding()
                } else {
                    ForEach(resultsManager.results, id: \.segmentId) { result in
                        HStack {
                            if let segmentInfo = segmentInfos[result.segmentId],
                               let imageUrl = generateImageUrl(objectId: segmentInfo.objectId, segmentId: result.segmentId) {
                                AsyncImage(url: imageUrl) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                ProgressView() // Placeholder while data is being loaded
                            }

                            VStack(alignment: .leading) {
                                Text(result.segmentId)
                                Text("Score: \(result.score, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        Divider() // Optional: Adds a separator between items
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Query Results")
        .task {
            await fetchSegmentInfos()
        }
    }

    // Fetch segment information using the client
    private func fetchSegmentInfos() async {
        do {
            let segmentIds = resultsManager.results.map { $0.segmentId }
            let fetchedInfos = try await client.getSegmentInfos(database: "mvk", segmentIds: segmentIds)

            // Map results for easier access
            let infoDictionary = Dictionary(
                uniqueKeysWithValues: fetchedInfos.map { info in
                    (info.segmentId, (objectId: info.objectId, segmentNumber: info.segmentNumber, segmentStart: info.segmentStart, segmentEnd: info.segmentEnd, segmentStartAbs: info.segmentStartAbs, segmentEndAbs: info.segmentEndAbs))
                }
            )
            DispatchQueue.main.async {
                self.segmentInfos = infoDictionary
                self.isLoading = false
            }
        } catch {
            // Handle errors (e.g., show an alert)
            print("Failed to fetch segment infos: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    // Helper function to generate the image URL
    private func generateImageUrl(objectId: String, segmentId: String) -> URL? {
        let baseURL = "http://localhost:8000/mvk/thumbnails/"
        let urlString = "\(baseURL)\(objectId)/\(segmentId).jpg"
        return URL(string: urlString)
    }
}
