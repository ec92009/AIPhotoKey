import Foundation

public enum AIModel: String, CaseIterable {
    case mobilenetV1 = "MobileNet SSD v1"
    case mobilenetV2 = "MobileNet SSD v2"
    case yoloV8n = "YOLOv8 Nano"
    case yoloV8s = "YOLOv8 Small"
    case yoloV8m = "YOLOv8 Medium"
    
    public var description: String {
        switch self {
        case .mobilenetV1:
            return "Fastest option, good for basic object detection"
        case .mobilenetV2:
            return "Improved accuracy over v1, still very fast"
        case .yoloV8n:
            return "Lightweight YOLO model, balanced speed and accuracy"
        case .yoloV8s:
            return "More accurate than Nano, slightly slower"
        case .yoloV8m:
            return "Most accurate, best for complex scenes"
        }
    }
    
    public var isYOLO: Bool {
        switch self {
        case .yoloV8n, .yoloV8s, .yoloV8m:
            return true
        default:
            return false
        }
    }
    
    public var isMobileNet: Bool {
        switch self {
        case .mobilenetV1, .mobilenetV2:
            return true
        default:
            return false
        }
    }
}
