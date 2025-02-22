import SwiftUI

public struct ResultsView: View {
    let photos: [String]
    let baseDirectory: String
    @State private var selectedPhoto: String?
    @State private var showingPreview = false
    @State private var previewPosition: CGPoint = .zero
    
    public init(photos: [String] = [], baseDirectory: String = "~/Photos") {
        self.photos = photos
        self.baseDirectory = (baseDirectory as NSString).expandingTildeInPath
    }
    
    private func getFullPath(for photo: String) -> String {
        return (baseDirectory as NSString).appendingPathComponent(photo)
    }
    
    public var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(photos, id: \.self) { photo in
                        Text(photo)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.primary)
                            .onTapGesture { location in
                                if selectedPhoto == photo {
                                    selectedPhoto = nil
                                    showingPreview = false
                                } else {
                                    selectedPhoto = photo
                                    showingPreview = true
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
            
            if showingPreview, let photo = selectedPhoto {
                PhotoPreviewView(imagePath: getFullPath(for: photo), isVisible: $showingPreview)
                    .position(x: NSScreen.main?.frame.width ?? 800 / 2,
                             y: NSScreen.main?.frame.height ?? 600 / 2)
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
