import SwiftUI
import AppKit

// Added extension to provide a 'description' property for NSSize (alias for CGSize)
extension NSSize {
    var dimensionsString: String {
        return "\(Int(width)) x \(Int(height))"
    }
}

public struct ResultsView: View {
    @StateObject private var viewModel: ResultsViewModel
    
    public init(photos: [String] = [], baseDirectory: String = "~/Photos") {
        _viewModel = StateObject(wrappedValue: ResultsViewModel(photos: photos, baseDirectory: baseDirectory))
    }
    
    public var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.photos, id: \.self) { photo in
                        Button(action: {
                            viewModel.handlePhotoClick(photo)
                        }) {
                            if let image = viewModel.loadImage(for: photo) {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 48, height: 48)
                                    .clipped()
                                    .cornerRadius(6)
                            } else {
                                Text("N/A")
                            }
                        }
                    }
                    
                    if viewModel.photos.isEmpty {
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
        .sheet(isPresented: $viewModel.showingDetail) {
            if let photo = viewModel.selectedPhoto {
                PhotoDetailView(model: PhotoDetailModel(
                    photo: photo,
                    confidence: viewModel.selectedConfidence,
                    baseDirectory: viewModel.baseDirectory
                ))
            }
        }
    }
}

class ResultsViewModel {
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

#Preview {
    ResultsView(photos: [
        "vacation/beach.jpg",
        "family/birthday.png",
        "raw/DSC0001.CR2"
    ])
    .frame(height: 300)
}
