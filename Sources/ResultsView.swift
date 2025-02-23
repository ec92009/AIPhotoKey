import SwiftUI
import AppKit

public struct ResultsView: View {
    let photos: [String]
    let baseDirectory: String
    @State private var selectedPhoto: String?
    @State private var showingDetail = false
    @State private var selectedConfidence: Double = 95
    
    public init(photos: [String] = [], baseDirectory: String = "~/Photos") {
        print("ResultsView init with \(photos.count) photos")
        self.photos = photos
        self.baseDirectory = (baseDirectory as NSString).expandingTildeInPath
        print("Base directory expanded to: \(self.baseDirectory)")
    }
    
    private func getFullPath(for photo: String) -> String {
        let fullPath = (baseDirectory as NSString).appendingPathComponent(photo)
        print("Full path for \(photo): \(fullPath)")
        return fullPath
    }
    
    private func handlePhotoClick(_ photo: String) {
        print("handlePhotoClick: \(photo)")
        print("Current state - selected: \(selectedPhoto ?? "none")")
        
        selectedPhoto = photo
        selectedConfidence = 95 // dummy confidence value
        showingDetail = true
        print("Showing details: selected: \(selectedPhoto ?? "none"), showing: \(showingDetail)")
    }
    
    public var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(photos, id: \.self) { photo in
                        Button(action: {
                            handlePhotoClick(photo)
                        }) {
                            if let image = NSImage(contentsOf: URL(fileURLWithPath: getFullPath(for: photo))) {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 48, height: 48)
                            } else {
                                Text("N/A")
                            }
                        }
                    }
                    
                    if photos.isEmpty {
                        Text("No photos found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
            }
            .background(.quaternary)
        }
        .sheet(isPresented: $showingDetail) {
            if let photo = selectedPhoto {
                PhotoDetailView(photo: photo, confidence: selectedConfidence, baseDirectory: baseDirectory)
            }
        }
    }
}

#Preview {
    ResultsView(photos: [
        "vacation/beach.jpg",
        "family/birthday.png",
        "raw/DSC0001.CR2"
    ])
    .frame(height: 300)
}

struct PhotoDetailView: View {
    let photo: String
    let confidence: Double
    let baseDirectory: String
    @Environment(\.dismiss) var dismiss
    var body: some View {
        let fullPath = (baseDirectory as NSString).appendingPathComponent(photo)
        let nsImage = NSImage(contentsOf: URL(fileURLWithPath: fullPath))
        VStack(spacing: 20) {
            if let nsImage = nsImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 512, height: 512)
            } else {
                Text("Image not available")
            }
            Text("Filename: \((photo as NSString).lastPathComponent)")
            Text("Confidence: \(Int(confidence))%")
            Button("Close") {
                dismiss()
            }
        }
        .padding()
        .frame(minWidth: 200, minHeight: 150)
    }
}

struct ThumbnailPopupView: View {
    var image: Image  // SwiftUI Image representing the photo thumbnail
    var confidence: Double
    var fileName: String

    var body: some View {
        VStack(spacing: 8) {
            image
                .resizable()
                .frame(width: 512, height: 512)
                .aspectRatio(contentMode: .fill)
                .clipped()
            Text(String(format: "%.0f%%", confidence * 100))
                .font(.caption)
            Text(fileName)
                .font(.caption)
        }
    }
}
