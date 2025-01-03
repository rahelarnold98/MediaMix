import SwiftUI
import AVKit
import FereLightSwiftClient

struct ResultsView: View {
    @EnvironmentObject var resultsManager: ResultsManager
    @State private var isLoading = true
    @State private var detailedSegments: [DetailedSegment] = []
    @State private var selectedSegment: DetailedSegment? // To track the selected segment for the popup
    @State private var showVideoPlayer = false // To control the sheet for the video player

    private var client: FereLightClient {
        FereLightClient(url: URL(string: ConfigurationManager.shared.apiBaseURL)!)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                if isLoading {
                    ProgressView("Loading data...")
                        .padding()
                } else {
                    ForEach(detailedSegments) { segment in
                        HStack {
                            if let imageUrl = generateImageUrl(objectId: segment.objectId, segmentId: segment.segmentId) {
                                AsyncImage(url: imageUrl) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                ProgressView()
                            }

                            VStack(alignment: .leading) {
                                Text(segment.segmentId)
                                Text("Score: \(segment.score, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Segment Number: \(segment.segmentNumber)")
                                Text("Start: \(segment.segmentStart), End: \(segment.segmentEnd)")
                            }
                            Spacer()
                        }
                        .padding()
                        .onTapGesture {
                            selectedSegment = segment
                            print("Selected segment: \(selectedSegment?.segmentId ?? "None")") // Debug the state update
                            showVideoPlayer = true
                        }
                        Divider()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Query Results")
        .task {
            await fetchDetailedSegments()
        }
        .sheet(item: $selectedSegment) { segment in
            VideoPlayerView(videoUrl: generateVideoUrl(objectId: segment.objectId))
        }
    }

    private func fetchDetailedSegments() async {
        do {
            isLoading = true
            let results = resultsManager.results
            let segmentIds = results.map { $0.segmentId }

            let fetchedInfos = try await client.getSegmentInfos(database: "mvk", segmentIds: segmentIds)

            let detailedSegments = results.compactMap { result -> DetailedSegment? in
                guard let info = fetchedInfos.first(where: { $0.segmentId == result.segmentId }) else {
                    return nil
                }
                return DetailedSegment(
                    segmentId: result.segmentId,
                    score: result.score,
                    objectId: info.objectId,
                    segmentNumber: info.segmentNumber,
                    segmentStart: info.segmentStart,
                    segmentEnd: info.segmentEnd,
                    segmentStartAbs: info.segmentStartAbs,
                    segmentEndAbs: info.segmentEndAbs
                )
            }

            DispatchQueue.main.async {
                self.detailedSegments = detailedSegments
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch detailed segments: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    private func generateImageUrl(objectId: String, segmentId: String) -> URL? {
        let baseURL = "http://localhost:8000/mvk/thumbnails/"
        let urlString = "\(baseURL)\(objectId)/\(segmentId).jpg"
        return URL(string: urlString)
    }

    private func generateVideoUrl(objectId: String) -> URL {
        let baseURL = "http://localhost:8000/mvk/videos/"
        let startIndex = objectId.index(objectId.startIndex, offsetBy: 2)
        let trimmedObjectId = objectId[startIndex...]
        let urlString = "\(baseURL)\(trimmedObjectId).mp4"
        print("Generated video URL: \(urlString)") // Debug output
        return URL(string: urlString)!
    }
}


struct VideoPlayerView: View {
    let videoUrl: URL

    var body: some View {
        VStack {
            if videoUrl.absoluteString.isEmpty {
                Text("Invalid video URL")
                    .foregroundColor(.red)
                    .font(.headline)
            } else {
                VideoPlayer(player: AVPlayer(url: videoUrl))
                    .onAppear {
                        print("Attempting to play video from URL: \(videoUrl)")
                    }
                    .onDisappear {
                        print("Video playback ended.")
                    }
                    .background(Color.black)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .background(Color.black.opacity(0.9))
    }
}
