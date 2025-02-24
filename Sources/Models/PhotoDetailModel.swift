import SwiftUI
import AppKit

public struct PhotoDetailModel {
    public let photo: String
    public let confidence: Double
    public let baseDirectory: String
    
    public var image: NSImage? {
        NSImage(contentsOf: URL(fileURLWithPath: (baseDirectory as NSString).appendingPathComponent(photo)))
    }
    
    public var filename: String {
        (photo as NSString).lastPathComponent
    }
    
    public var size: String {
        image?.size.dimensionsString ?? "N/A"
    }
    
    public init(photo: String, confidence: Double, baseDirectory: String) {
        self.photo = photo
        self.confidence = confidence
        self.baseDirectory = baseDirectory
    }
}
