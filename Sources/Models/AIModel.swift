import Foundation

public enum AIModel: String, CaseIterable {
    // MobileNet Models
    case mobilenetV1 = "MobileNet SSD v1"
    case mobilenetV2 = "MobileNet SSD v2"
    
    // YOLO Models
    case yoloV8n = "YOLOv8 Nano"
    case yoloV8s = "YOLOv8 Small"
    case yoloV8m = "YOLOv8 Medium"
    
    // CLIP Model
    case openaiCLIP = "OpenAI CLIP"
    
    public var description: String {
        switch self {
        case .mobilenetV1:
            return "Fastest option, optimized for Apple Silicon. Detects 80+ object types. Model size: ~4.3MB"
        case .mobilenetV2:
            return "Improved accuracy over v1, still very fast. Detects 80+ object types. Model size: ~9MB"
        case .yoloV8n:
            return "Lightweight YOLO model, balanced speed/accuracy. Detects 80 object types. Model size: ~6.2MB"
        case .yoloV8s:
            return "More accurate than Nano, slightly slower. Detects 80 object types. Model size: ~22.4MB"
        case .yoloV8m:
            return "Most accurate YOLO variant, best for complex scenes. Detects 80 object types. Model size: ~48.6MB"
        case .openaiCLIP:
            return "Can identify thousands of objects and concepts. No bounding boxes. Model size: ~325MB"
        }
    }
    
    public var modelSize: Int {
        switch self {
        case .mobilenetV1: return 4_300_000    // 4.3MB
        case .mobilenetV2: return 9_000_000    // 9MB
        case .yoloV8n:    return 6_200_000    // 6.2MB
        case .yoloV8s:    return 22_400_000   // 22.4MB
        case .yoloV8m:    return 48_600_000   // 48.6MB
        case .openaiCLIP: return 325_000_000  // 325MB
        }
    }
    
    public var license: String {
        switch self {
        case .mobilenetV1, .mobilenetV2:
            return "Apache 2.0"
        case .yoloV8n, .yoloV8s, .yoloV8m:
            return "MIT License"
        case .openaiCLIP:
            return "MIT License"
        }
    }
    
    public var capabilities: ModelCapabilities {
        switch self {
        case .mobilenetV1, .mobilenetV2:
            return ModelCapabilities(
                objectTypes: 80,
                hasBoundingBoxes: true,
                hasConfidenceScores: true,
                supportsRealTime: true,
                minimumImageSize: CGSize(width: 224, height: 224)
            )
        case .yoloV8n, .yoloV8s, .yoloV8m:
            return ModelCapabilities(
                objectTypes: 80,
                hasBoundingBoxes: true,
                hasConfidenceScores: true,
                supportsRealTime: true,
                minimumImageSize: CGSize(width: 640, height: 640)
            )
        case .openaiCLIP:
            return ModelCapabilities(
                objectTypes: 10000,
                hasBoundingBoxes: false,
                hasConfidenceScores: true,
                supportsRealTime: false,
                minimumImageSize: CGSize(width: 224, height: 224)
            )
        }
    }
    
    public var sourceURL: String {
        switch self {
        case .mobilenetV1, .mobilenetV2:
            return "https://github.com/tensorflow/models/tree/master/research/object_detection"
        case .yoloV8n, .yoloV8s, .yoloV8m:
            return "https://github.com/ultralytics/ultralytics"
        case .openaiCLIP:
            return "https://github.com/openai/CLIP"
        }
    }
}

public struct ModelCapabilities {
    public let objectTypes: Int
    public let hasBoundingBoxes: Bool
    public let hasConfidenceScores: Bool
    public let supportsRealTime: Bool
    public let minimumImageSize: CGSize
}
