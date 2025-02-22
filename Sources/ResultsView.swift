import SwiftUI

public struct ResultsView: View {
    let photos: [String]
    
    public init(photos: [String] = []) {
        self.photos = photos
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(photos, id: \.self) { photo in
                    Text(photo)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.primary)
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
}

#Preview {
    ResultsView(photos: [
        "vacation/beach.jpg",
        "family/birthday.png",
        "raw/DSC0001.CR2"
    ])
    .frame(height: 300)
}
