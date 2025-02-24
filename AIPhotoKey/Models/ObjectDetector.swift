import Foundation
import Vision
import CoreML
import AppKit

@MainActor
public class ObjectDetector {
    private let modelManager: ModelManager
    
    init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }
    
    func detectObjects(in imagePath: String, model: AIModel, confidenceThreshold: Double) async throws -> [Detection] {
        guard let image = NSImage(contentsOfFile: imagePath) else {
            print("Failed to load image at path: \(imagePath)")
            throw DetectionError.imageLoadFailed
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw DetectionError.imageConversionFailed
        }
        
        var detections: [Detection] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        do {
            let visionModel = try modelManager.loadModel(model)
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                defer { semaphore.signal() }
                
                if let error = error {
                    print("Vision ML Request Error: \(error)")
                    return
                }
                
                if let results = request.results as? [VNRecognizedObjectObservation] {
                    // Handle object detection results
                    detections = results
                        .filter { $0.confidence >= Float(confidenceThreshold) }
                        .compactMap { observation -> Detection? in
                            guard let label = observation.labels.first?.identifier else { return nil }
                            return Detection(label: label, confidence: Double(observation.confidence))
                        }
                } else if let results = request.results as? [VNClassificationObservation] {
                    // Handle classification results
                    detections = results
                        .filter { $0.confidence >= Float(confidenceThreshold) }
                        .map { Detection(label: $0.identifier, confidence: Double($0.confidence)) }
                } else {
                    print("Unexpected result type from VNCoreMLRequest")
                }
            }
            
            request.imageCropAndScaleOption = .scaleFit
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try handler.perform([request])
            
            semaphore.wait()
            return detections
            
        } catch {
            throw DetectionError.modelError(error)
        }
    }
}

enum DetectionError: Error {
    case imageLoadFailed
    case imageConversionFailed
    case modelError(Error)
}
