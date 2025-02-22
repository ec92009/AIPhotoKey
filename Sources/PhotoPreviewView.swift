import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PreviewWindow: View {
    let imagePath: String
    
    var body: some View {
        VStack {
            Text("Preview Window")
                .font(.title)
            Text(imagePath)
                .font(.caption)
            Rectangle()
                .fill(.red)
                .frame(width: 400, height: 400)
        }
        .frame(width: 500, height: 500)
        .background(Color(.windowBackgroundColor))
    }
}

class PreviewWindowController {
    static let shared = PreviewWindowController()
    private var previewWindow: NSWindow?
    
    private init() {
        print("PreviewWindowController initialized")
    }
    
    public func showPreview(imagePath: String) {
        print("\n=== Starting Preview Generation ===")
        print("ShowPreview called with path: \(imagePath)")
        
        // Close existing window if any
        if let existing = previewWindow {
            print("Closing existing window")
            existing.close()
            previewWindow = nil
        }
        
        print("Creating new window")
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        print("Configuring window")
        window.title = "Photo Preview"
        window.isReleasedWhenClosed = false
        window.center()
        
        print("Creating SwiftUI view")
        let previewView = PreviewWindow(imagePath: imagePath)
        window.contentView = NSHostingView(rootView: previewView)
        
        print("Making window visible")
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        
        print("Storing window reference")
        self.previewWindow = window
        
        // Debug window state
        print("Window state:")
        print(" - Is visible: \(window.isVisible)")
        print(" - Is key: \(window.isKeyWindow)")
        print(" - Is main: \(window.isMainWindow)")
        print(" - Frame: \(window.frame)")
        print(" - Screen: \(String(describing: window.screen))")
    }
    
    public func closePreview() {
        print("Closing preview window")
        if let window = previewWindow {
            print(" - Window exists, closing it")
            window.close()
        } else {
            print(" - No window to close")
        }
        previewWindow = nil
    }
}

public struct PhotoPreviewView: View {
    let imagePath: String
    @Binding var isVisible: Bool
    
    public init(imagePath: String, isVisible: Binding<Bool>) {
        print("PhotoPreviewView init: \(imagePath)")
        print("Initial isVisible value: \(isVisible.wrappedValue)")
        self.imagePath = imagePath
        self._isVisible = isVisible
    }
    
    public var body: some View {
        EmptyView()
            .onAppear {
                print("\n=== PhotoPreviewView appeared ===")
                print("isVisible in onAppear: \(isVisible)")
                if isVisible {
                    print("Showing preview window")
                    DispatchQueue.main.async {
                        PreviewWindowController.shared.showPreview(imagePath: imagePath)
                    }
                }
            }
            .onChange(of: isVisible) { newValue in
                print("\n=== isVisible changed to: \(newValue) ===")
                if newValue {
                    print("Showing preview window")
                    DispatchQueue.main.async {
                        PreviewWindowController.shared.showPreview(imagePath: imagePath)
                    }
                } else {
                    print("Closing preview window")
                    PreviewWindowController.shared.closePreview()
                }
            }
            .onDisappear {
                print("\n=== PhotoPreviewView disappearing ===")
                PreviewWindowController.shared.closePreview()
            }
    }
}
