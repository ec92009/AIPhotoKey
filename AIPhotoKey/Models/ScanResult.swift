import Foundation

public struct ScanResult: Hashable {
    public let photoPath: String
    public let detections: [Detection]
    
    public init(photoPath: String, detections: [Detection]) {
        self.photoPath = photoPath
        self.detections = detections
    }
}

public struct Detection: Hashable {
    public let label: String
    public let confidence: Double
    
    public init(label: String, confidence: Double) {
        self.label = label
        self.confidence = confidence
    }
}
