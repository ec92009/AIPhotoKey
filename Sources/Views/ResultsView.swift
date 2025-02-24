import SwiftUI
import AppKit

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

#Preview {
    ResultsView(photos: [
        "vacation/beach.jpg",
        "family/birthday.png",
        "raw/DSC0001.CR2"
    ])
    .frame(height: 300)
}
