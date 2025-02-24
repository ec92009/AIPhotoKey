import SwiftUI
import AppKit

struct PhotoDetailModel {
    let photo: String
    let confidence: Double
    let baseDirectory: String
    
    var image: NSImage? {
        NSImage(contentsOf: URL(fileURLWithPath: (baseDirectory as NSString).appendingPathComponent(photo)))
    }
    
    var filename: String {
        (photo as NSString).lastPathComponent
    }
    
    var size: String {
        image?.size.dimensionsString ?? "N/A"
    }
}
