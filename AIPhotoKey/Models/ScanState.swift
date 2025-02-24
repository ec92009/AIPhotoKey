import Foundation

public enum ScanState {
    case notStarted
    case scanning
    case paused
    case completed
    
    public var isActive: Bool {
        switch self {
        case .scanning:
            return true
        default:
            return false
        }
    }
    
    public var buttonTitle: String {
        switch self {
        case .notStarted:
            return "Start Scan"
        case .scanning:
            return "Pause Scan"
        case .paused:
            return "Resume Scan"
        case .completed:
            return "Start New Scan"
        }
    }
}
