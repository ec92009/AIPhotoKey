import SwiftUI
import AppKit

struct ClickableText: NSViewRepresentable {
    let text: String
    let action: () -> Void
    
    func makeNSView(context: Context) -> NSButton {
        print("Creating button for: \(text)")
        let button = NSButton(title: text, target: context.coordinator, action: #selector(Coordinator.handleClick))
        button.bezelStyle = .inline
        button.isBordered = false
        button.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        return button
    }
    
    func updateNSView(_ nsView: NSButton, context: Context) {
        nsView.title = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func handleClick() {
            print("Button clicked!")
            action()
        }
    }
}

public struct ResultsView: View {
    let photos: [String]
    let baseDirectory: String
    @State private var selectedPhoto: String?
    @State private var showingPreview = false
    
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
        print("Current state - selected: \(selectedPhoto ?? "none"), showing: \(showingPreview)")
        
        // First update selected photo
        selectedPhoto = photo
        
        // Then handle preview visibility
        if !showingPreview {
            print("Showing preview")
            showingPreview = true
        }
        
        print("New state - selected: \(selectedPhoto ?? "none"), showing: \(showingPreview)")
    }
    
    public var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(photos, id: \.self) { photo in
                        ClickableText(text: photo) {
                            handlePhotoClick(photo)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 2)
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
