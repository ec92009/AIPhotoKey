import Foundation
import CoreGraphics

extension Int64 {
    public var formattedFileSize: String {
        return ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

extension Double {
    public var percentFormatted: String {
        return String(format: "%.1f%%", self * 100)
    }
}

extension CGSize {
    public var dimensionsString: String {
        return "\(Int(width))×\(Int(height))"
    }
}
