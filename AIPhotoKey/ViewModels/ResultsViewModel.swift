import Foundation
import AppKit
import Models

public class ResultsViewModel: ObservableObject {
    private var imageCache: [String: NSImage] = [:]
    private let baseDirectory: String
    private let scanner: PhotoScanner
    private let modelManager: ModelManager
    
    public init(baseDirectory: String, scanner: PhotoScanner, modelManager: ModelManager) {
        self.baseDirectory = baseDirectory
        self.scanner = scanner
        self.modelManager = modelManager
    }
    
    func loadImage(path: String) async -> NSImage? {
        // Check cache first
        if let cachedImage = imageCache[path] {
            return cachedImage
        }
        
        // Load image from disk
        let fullPath = (baseDirectory as NSString).appendingPathComponent(path)
        guard let image = NSImage(contentsOfFile: fullPath) else {
            print("Failed to load image at path: \(fullPath)")
            return nil
        }
        
        // Cache the image
        imageCache[path] = image
        return image
    }
}
