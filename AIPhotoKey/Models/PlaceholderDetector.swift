import Vision
import CoreML

// This is a temporary placeholder until we integrate the real ML models
class PlaceholderDetector {
    static func detect(image: CGImage) -> [VNClassificationObservation] {
        let observations = [
            MockClassification(identifier: "person", confidence: 0.95),
            MockClassification(identifier: "dog", confidence: 0.85),
            MockClassification(identifier: "car", confidence: 0.75)
        ]
        // Hold strong reference to observations to prevent deallocation
        return observations
    }
}

final class MockClassification: VNClassificationObservation {
    private let mockIdentifier: String
    private let mockConfidence: Float
    
    init(identifier: String, confidence: Float) {
        self.mockIdentifier = identifier
        self.mockConfidence = confidence
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var identifier: String {
        return mockIdentifier
    }
    
    override var confidence: Float {
        return mockConfidence
    }
}
