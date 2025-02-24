import Foundation

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
