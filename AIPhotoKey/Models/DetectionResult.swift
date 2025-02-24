import Foundation

public struct DetectionResult: Identifiable {
    public let id = UUID()
    public let label: String
    public let confidence: Double
    
    public init(label: String, confidence: Double) {
        self.label = label
        self.confidence = confidence
    }
}

public struct PhotoAnalysis {
    public let path: String
    public let detections: [DetectionResult]
    
    public init(path: String, detections: [DetectionResult]) {
        self.path = path
        self.detections = detections
    }
    
    public var hasValidDetections: Bool {
        !detections.isEmpty
    }
}
