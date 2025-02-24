import SwiftUI
import AppKit

class ResultsViewModel: ObservableObject {
    @Published var photos: [String]
    @Published var baseDirectory: String
    @Published var selectedPhoto: String?
    @Published var selectedConfidence: Double = 95
    @Published var showingDetail = false
    
    init(photos: [String], baseDirectory: String) {
        print("ResultsViewModel init with \(photos.count) photos")
        self.photos = photos
        self.baseDirectory = (baseDirectory as NSString).expandingTildeInPath
        print("Base directory expanded to: \(self.baseDirectory)")
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
        let fullPath = (baseDirectory as NSString).appendingPathComponent(photo)
        print("Full path for \(photo): \(fullPath)")
        return NSImage(contentsOf: URL(fileURLWithPath: fullPath))
    }
}
