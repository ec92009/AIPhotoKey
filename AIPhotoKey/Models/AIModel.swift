import Foundation

public enum AIModel: String, CaseIterable {
    // YOLO Models
    case yoloV8n = "yolov8n"
    case yoloV8s = "yolov8s"
    case yoloV8m = "yolov8m"
    case yoloV8n6 = "yolov8n6"
    case yoloV8s6 = "yolov8s6"
    case yoloV8m6 = "yolov8m6"
    case yoloV8l = "yolov8l"
    case yoloV8x = "yolov8x"
    case yoloV8x6 = "yolov8x6"
    
    // MobileNet Models
    case mobilenetV1 = "mobilenetv1"
    case mobilenetV2 = "mobilenetv2"
    
    // CLIP Model
    case openaiCLIP = "OpenAI CLIP"
    
    public var displayName: String {
        switch self {
        case .yoloV8n:
            return "YOLOv8 Nano"
        case .yoloV8s:
            return "YOLOv8 Small"
        case .yoloV8m:
            return "YOLOv8 Medium"
        case .yoloV8n6:
            return "YOLOv8 Nano 6"
        case .yoloV8s6:
            return "YOLOv8 Small 6"
        case .yoloV8m6:
            return "YOLOv8 Medium 6"
        case .yoloV8l:
            return "YOLOv8 Large"
        case .yoloV8x:
            return "YOLOv8 X-Large"
        case .yoloV8x6:
            return "YOLOv8 X-Large 6"
        case .mobilenetV1:
            return "MobileNet v1"
        case .mobilenetV2:
            return "MobileNet v2"
        case .openaiCLIP:
            return "OpenAI CLIP"
        }
    }
    
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
        case .yoloV8n6:
            return "Lightweight YOLO model, balanced speed/accuracy. Detects 80 object types. Model size: ~6.2MB"
        case .yoloV8s6:
            return "More accurate than Nano, slightly slower. Detects 80 object types. Model size: ~22.4MB"
        case .yoloV8m6:
            return "Most accurate YOLO variant, best for complex scenes. Detects 80 object types. Model size: ~48.6MB"
        case .yoloV8l:
            return "Large YOLO model, best for complex scenes. Detects 80 object types. Model size: ~74.5MB"
        case .yoloV8x:
            return "Extra Large YOLO model, best for complex scenes. Detects 80 object types. Model size: ~139.5MB"
        case .yoloV8x6:
            return "Extra Large YOLO model, best for complex scenes. Detects 80 object types. Model size: ~139.5MB"
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
        case .yoloV8n6:    return 6_200_000    // 6.2MB
        case .yoloV8s6:    return 22_400_000   // 22.4MB
        case .yoloV8m6:    return 48_600_000   // 48.6MB
        case .yoloV8l:    return 74_500_000   // 74.5MB
        case .yoloV8x:    return 139_500_000   // 139.5MB
        case .yoloV8x6:    return 139_500_000   // 139.5MB
        case .openaiCLIP: return 325_000_000  // 325MB
        }
    }
    
    public var license: String {
        switch self {
        case .mobilenetV1, .mobilenetV2:
            return "Apache 2.0"
        case .yoloV8n, .yoloV8s, .yoloV8m, .yoloV8n6, .yoloV8s6, .yoloV8m6, .yoloV8l, .yoloV8x, .yoloV8x6:
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
        case .yoloV8n, .yoloV8s, .yoloV8m, .yoloV8n6, .yoloV8s6, .yoloV8m6, .yoloV8l, .yoloV8x, .yoloV8x6:
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
        case .yoloV8n, .yoloV8s, .yoloV8m, .yoloV8n6, .yoloV8s6, .yoloV8m6, .yoloV8l, .yoloV8x, .yoloV8x6:
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
