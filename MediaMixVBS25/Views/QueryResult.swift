import SwiftUI

struct QueryResult: Identifiable {
    var segmentId: String
    let score: Double

    var id: String { segmentId }
}
