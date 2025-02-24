import Foundation
import AppKit

public class ModelManager: ObservableObject {
    @Published public var selectedModel: AIModel = .mobilenetV1
    @Published public var scanState: ScanState = .idle
    @Published public var progress: Double = 0.0
    @Published public var currentFile: String = ""
    
    public init() {}
    
    public func startScanning() {
        scanState = .scanning
    }
    
    public func pauseScanning() {
        scanState = .paused
    }
    
    public func stopScanning() {
        scanState = .finished
    }
    
    public func resetScanning() {
        scanState = .idle
        progress = 0.0
        currentFile = ""
    }
    
    public func updateProgress(_ newProgress: Double, currentFile: String) {
        self.progress = newProgress
        self.currentFile = currentFile
    }
}
