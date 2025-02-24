import SwiftUI
import Models

struct ResultsView: View {
    let baseDirectory: String
    @ObservedObject var scanner: PhotoScanner
    @ObservedObject var modelManager: ModelManager
    @StateObject private var viewModel: ResultsViewModel
    
    init(baseDirectory: String, scanner: PhotoScanner, modelManager: ModelManager) {
        self.baseDirectory = baseDirectory
        self.scanner = scanner
        self.modelManager = modelManager
        _viewModel = StateObject(wrappedValue: ResultsViewModel(baseDirectory: baseDirectory, scanner: scanner, modelManager: modelManager))
    }
    
    var body: some View {
        List(scanner.results, id: \.photoPath) { result in
            ResultRow(result: result, viewModel: viewModel)
        }
        .listStyle(.plain)
    }
}

struct ResultRow: View {
    let result: ScanResult
    @ObservedObject var viewModel: ResultsViewModel
    @State private var isImageLoaded = false
    @State private var image: NSImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Photo name and path
            Text(result.photoPath)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            
            // Image and detection results side by side
            HStack(alignment: .top, spacing: 20) {
                // Image thumbnail
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                
                // Detection results
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(result.detections, id: \.self) { detection in
                        HStack {
                            Text(detection.label)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Text(String(format: "%.1f%%", detection.confidence * 100))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard !isImageLoaded else { return }
        
        Task {
            if let loadedImage = await viewModel.loadImage(path: result.photoPath) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                    self.isImageLoaded = true
                }
            }
        }
    }
}

#Preview {
    let modelManager = ModelManager()
    return ResultsView(
        baseDirectory: "/tmp",
        scanner: PhotoScanner(modelManager: modelManager),
        modelManager: modelManager
    )
}
