import Foundation

public enum ScanState {
    case idle
    case scanning
    case paused
    case finished
    
    public var isActive: Bool {
        switch self {
        case .scanning:
            return true
        default:
            return false
        }
    }
}
