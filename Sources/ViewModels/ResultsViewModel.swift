import SwiftUI
import AppKit

class ResultsViewModel: ObservableObject {
    @Published var selectedPhoto: String?
    @Published var showingDetail: Bool = false
    @Published var selectedConfidence: Double = 95
    
    let photos: [String]
    let baseDirectory: String
    
    init(photos: [String] = [], baseDirectory: String = "~/Photos") {
        self.photos = photos
        self.baseDirectory = (baseDirectory as NSString).expandingTildeInPath
        print("ResultsViewModel init with \(photos.count) photos")
        print("Base directory expanded to: \(self.baseDirectory)")
    }
    
    func getFullPath(for photo: String) -> String {
        let fullPath = (baseDirectory as NSString).appendingPathComponent(photo)
        print("Full path for \(photo): \(fullPath)")
        return fullPath
    }
    
    func handlePhotoClick(_ photo: String) {
        print("handlePhotoClick: \(photo)")
        print("Current state - selected: \(selectedPhoto ?? "none")")
        
        selectedPhoto = photo
        selectedConfidence = 95 // dummy confidence value
        showingDetail = true
        print("Showing details: selected: \(selectedPhoto ?? "none"), showing: \(showingDetail)")
    }
    
    func loadImage(for photo: String) -> NSImage? {
        NSImage(contentsOf: URL(fileURLWithPath: getFullPath(for: photo)))
    }
}

struct PhotoDetailModel {
    let photo: String
    let confidence: Double
    let baseDirectory: String
    
    var fullPath: String {
        (baseDirectory as NSString).appendingPathComponent(photo)
    }
    
    var filename: String {
        (photo as NSString).lastPathComponent
    }
    
    var image: NSImage? {
        NSImage(contentsOf: URL(fileURLWithPath: fullPath))
    }
    
    var size: String {
        image?.size.dimensionsString ?? "N/A"
    }
}
