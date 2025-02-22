import SwiftUI

public struct PhotoPreviewView: View {
    let imagePath: String
    @Binding var isVisible: Bool
    
    public init(imagePath: String, isVisible: Binding<Bool>) {
        self.imagePath = imagePath
        self._isVisible = isVisible
    }
    
    public var body: some View {
        if let nsImage = NSImage(contentsOfFile: imagePath) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 512, maxHeight: 512)
                .background(Color(.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 10)
                .onTapGesture {
                    isVisible = false
                }
        } else {
            Text("Unable to load image")
                .foregroundColor(.red)
                .padding()
                .background(Color(.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 10)
                .onTapGesture {
                    isVisible = false
                }
        }
    }
}
