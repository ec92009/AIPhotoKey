import SwiftUI
import Foundation

public class PhotoScanner: ObservableObject {
    @Published public private(set) var foundPhotos: [String] = []
    @Published public private(set) var isScanning = false
    @Published public private(set) var statusMessage = "Ready"
    
    public var onScanComplete: (() -> Void)?
    
    private let photoExtensions = [
        // Standard formats
        "jpg", "jpeg", "png", "heic", "heif", "gif", "tiff", "tif", "bmp",
        // Raw formats
        "raw", "cr2", "cr3", "nef", "arw", "dng", "orf", "rw2", "pef", "srw",
        // Adobe formats
        "psd", "psb"
    ]
    
    private var currentEnumerator: FileManager.DirectoryEnumerator?
    private var currentPath: String?
    
    public init() {}
    
    public func clearDatabase() {
        foundPhotos = []
        statusMessage = "Database cleared"
        isScanning = false
        currentEnumerator = nil
        currentPath = nil
    }
    
    public func startScan(path: String) {
        isScanning = true
        statusMessage = "Scanning for photos..."
        foundPhotos = []
        currentPath = path
        
        scanDirectory()
    }
    
    public func resumeScan() {
        guard let path = currentPath else { return }
        isScanning = true
        statusMessage = "Resuming scan..."
        
        if currentEnumerator == nil {
            // If we don't have an enumerator, start fresh
            scanDirectory()
        } else {
            // Continue with existing enumerator
            continueScanning()
        }
    }
    
    private func scanDirectory() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let path = self.currentPath else { return }
            
            let expandedPath = (path as NSString).expandingTildeInPath
            let fileManager = FileManager.default
            
            guard fileManager.fileExists(atPath: expandedPath) else {
                self.updateStatus("Error: Directory not found")
                return
            }
            
            self.currentEnumerator = fileManager.enumerator(
                at: URL(fileURLWithPath: expandedPath),
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            
            self.continueScanning()
        }
    }
    
    private func continueScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let enumerator = self.currentEnumerator,
                  let path = self.currentPath else { return }
            
            let expandedPath = (path as NSString).expandingTildeInPath
            
            do {
                while let url = enumerator.nextObject() as? URL {
                    guard self.isScanning else { break }
                    
                    if let resources = try? url.resourceValues(forKeys: [.isRegularFileKey]),
                       resources.isRegularFile == true,
                       let ext = url.pathExtension.lowercased() as String?,
                       self.photoExtensions.contains(ext) {
                        let relativePath = url.path.replacingOccurrences(of: expandedPath + "/", with: "")
                        
                        DispatchQueue.main.async {
                            self.foundPhotos.append(relativePath)
                            self.statusMessage = "Found \(self.foundPhotos.count) photos..."
                        }
                        
                        // Simulate processing time
                        Thread.sleep(forTimeInterval: 0.02)
                        
                        if self.foundPhotos.count >= 3000 {
                            break
                        }
                    }
                }
                
                // If we completed the scan, clear the enumerator
                if !self.isScanning || self.foundPhotos.count >= 3000 {
                    self.currentEnumerator = nil
                }
                
                DispatchQueue.main.async {
                    self.isScanning = false
                    self.statusMessage = "Found \(self.foundPhotos.count) photos"
                    self.onScanComplete?()
                }
                
            } catch {
                self.updateStatus("Error: \(error.localizedDescription)")
            }
        }
    }
    
    public func stopScan() {
        isScanning = false
        statusMessage = "Scan paused"
    }
    
    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusMessage = message
            self.isScanning = false
        }
    }
}
