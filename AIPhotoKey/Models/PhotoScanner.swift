import Foundation
import AppKit
import Models
import Combine

@MainActor
public final class PhotoScanner: ObservableObject {
    @Published public private(set) var results: [ScanResult] = []
    @Published public private(set) var isScanning = false
    @Published public private(set) var statusMessage = "Ready to scan"
    
    private let modelManager: ModelManager
    private var task: Task<Void, Never>?
    
    public init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }
    
    public func startScan(path: String, model: AIModel, confidence: Double) {
        isScanning = true
        statusMessage = "Starting scan..."
        results.removeAll()
        
        task = Task { [weak self] in
            guard let self = self else { return }
            
            let detector = ObjectDetector(modelManager: modelManager)
            let expandedPath = (path as NSString).expandingTildeInPath
            let fileManager = FileManager.default
            
            guard let enumerator = fileManager.enumerator(atPath: expandedPath) else {
                await self.updateStatus("Failed to access directory: \(path)")
                await MainActor.run {
                    self.isScanning = false
                }
                return
            }
            
            while let filePath = enumerator.nextObject() as? String {
                // Check if we should stop
                guard await self.isScanning else { break }
                
                let fullPath = (expandedPath as NSString).appendingPathComponent(filePath)
                let pathExtension = (filePath as NSString).pathExtension.lowercased()
                
                // Only process image files
                guard ["jpg", "jpeg", "png"].contains(pathExtension) else { continue }
                
                await self.updateStatus("Processing: \(filePath)")
                
                do {
                    let detections = try await detector.detectObjects(
                        in: fullPath,
                        model: model,
                        confidenceThreshold: confidence
                    )
                    
                    let result = ScanResult(
                        photoPath: filePath,
                        detections: detections
                    )
                    
                    await MainActor.run {
                        self.results.append(result)
                    }
                } catch {
                    print("Error processing \(filePath): \(error)")
                }
            }
            
            await MainActor.run {
                self.statusMessage = self.isScanning ? "Scan completed" : "Scan paused"
                self.isScanning = false
            }
        }
    }
    
    public func pauseScan() {
        isScanning = false
        statusMessage = "Scan paused"
    }
    
    public func resumeScan() {
        isScanning = true
        statusMessage = "Resuming scan..."
    }
    
    public func clearDatabase() {
        results.removeAll()
        statusMessage = "Database cleared"
    }
    
    private func updateStatus(_ message: String) {
        Task { @MainActor in
            self.statusMessage = message
        }
    }
}
