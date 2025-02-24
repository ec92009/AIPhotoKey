import SwiftUI
import AppKit
import Models

struct PhotoDetailView: View {
    let model: PhotoDetailModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                if let image = model.image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 512, height: 512)
                } else {
                    Text("Image not available")
                }
                Text("Filename: \(model.filename)")
                Text("Confidence: \(Int(model.confidence))%")
                Text("Original Size: \(model.size)")
                Spacer()
            }
            .padding()
            .frame(minWidth: 200, minHeight: 150)
            
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
