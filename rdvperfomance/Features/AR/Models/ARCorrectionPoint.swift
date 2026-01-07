import Foundation
import simd

struct ARVector3Codable: Codable, Hashable {
    var x: Float
    var y: Float
    var z: Float

    init(x: Float = 0, y: Float = 0, z: Float = 0) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(from simd: SIMD3<Float>) {
        self.x = simd.x
        self.y = simd.y
        self.z = simd.z
    }

    var simd: SIMD3<Float> { SIMD3<Float>(x, y, z) }
}

struct ARCorrectionPoint: Codable, Identifiable, Hashable {
    let id: String
    var title: String?
    var note: String?
    var position: ARVector3Codable
    var createdBy: String?
    var timestamp: Date

    init(id: String = UUID().uuidString,
         title: String? = nil,
         note: String? = nil,
         position: ARVector3Codable = ARVector3Codable(),
         createdBy: String? = nil,
         timestamp: Date = Date()) {
        self.id = id
        self.title = title
        self.note = note
        self.position = position
        self.createdBy = createdBy
        self.timestamp = timestamp
    }
}
