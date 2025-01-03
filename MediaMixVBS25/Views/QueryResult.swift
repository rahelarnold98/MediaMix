import SwiftUI

struct QueryResult: Identifiable {
    var segmentId: String
    let score: Double

    var id: String { segmentId }
}

struct DetailedSegment: Identifiable {
    var segmentId: String
    let score: Double
    let objectId: String
    let segmentNumber: Int
    let segmentStart: Int
    let segmentEnd: Int
    let segmentStartAbs: Double
    let segmentEndAbs: Double

    var id: String { segmentId }
}
