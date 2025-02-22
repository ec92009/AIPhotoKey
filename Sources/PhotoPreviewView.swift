import SwiftUI
import AppKit

class PreviewWindowController: NSWindowController, NSWindowDelegate {
    private let onClose: () -> Void
    
    init(imagePath: String, onClose: @escaping () -> Void) {
        self.onClose = onClose
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 512, height: 512),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = (imagePath as NSString).lastPathComponent
        window.center()
        
        let hostingView = NSHostingView(rootView: 
            PhotoPreviewContent(imagePath: imagePath)
        )
        window.contentView = hostingView
        
        super.init(window: window)
        window.delegate = self
    }
    
    required init?(coder: NSCoder) {
        self.onClose = {}
        super.init(coder: coder)
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

private struct PhotoPreviewContent: View {
    let imagePath: String
    
    var body: some View {
        VStack {
            if let nsImage = NSImage(contentsOfFile: imagePath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 512, maxHeight: 512)
            } else {
                Text("Unable to load image")
                    .foregroundColor(.red)
                    .padding()
            }
            Text((imagePath as NSString).lastPathComponent)
                .font(.system(.caption, design: .monospaced))
                .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

public struct PhotoPreviewView: View {
    let imagePath: String
    @Binding var isVisible: Bool
    @State private var windowController: PreviewWindowController?
    
    public init(imagePath: String, isVisible: Binding<Bool>) {
        self.imagePath = imagePath
        self._isVisible = isVisible
    }
    
    public var body: some View {
        Color.clear
            .onChange(of: isVisible) { newValue in
                if newValue {
                    windowController = PreviewWindowController(imagePath: imagePath) {
                        isVisible = false
                        windowController = nil
                    }
                    windowController?.showWindow(nil)
                } else {
                    windowController?.close()
                    windowController = nil
                }
            }
    }
}
