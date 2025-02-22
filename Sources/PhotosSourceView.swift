import SwiftUI
import AppKit

public struct PhotosSourceView: View {
    @Binding var photosPath: String
    
    public init(photosPath: Binding<String>) {
        self._photosPath = photosPath
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Text("Photos Source:")
                .font(.headline)
            TextField("", text: $photosPath)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("...") {
                let openPanel = NSOpenPanel()
                openPanel.allowsMultipleSelection = false
                openPanel.canChooseDirectories = true
                openPanel.canChooseFiles = false
                openPanel.canCreateDirectories = false
                openPanel.treatsFilePackagesAsDirectories = true
                openPanel.directoryURL = URL(string: NSString(string: "~/Photos").expandingTildeInPath)
                
                openPanel.begin { response in
                    if response == .OK {
                        if let url = openPanel.url {
                            photosPath = url.path
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PhotosSourceView(photosPath: .constant("~/Photos"))
        .padding()
}
