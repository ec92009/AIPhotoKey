import Foundation
import AppKit
import Models
import CoreML
import Vision

@MainActor
public final class ModelManager: ObservableObject, Sendable {
    @Published public var selectedAIModel: AIModel = .yoloV8n
    @Published public var scanState: ScanState = .notStarted
    @Published public var progress: Double = 0.0
    @Published public var currentFile: String = ""
    @Published public private(set) var downloadedModels: Set<AIModel> = []
    
    private let modelURLs: [AIModel: String] = [
        .yoloV8n: "https://ml-assets.apple.com/coreml/models/Image/ObjectDetection/YOLOv3/YOLOv3.mlmodel",
        .yoloV8s: "https://ml-assets.apple.com/coreml/models/Image/ObjectDetection/YOLOv3Tiny/YOLOv3Tiny.mlmodel",
        .mobilenetV1: "https://ml-assets.apple.com/coreml/models/Image/ImageClassification/MobileNetV2/MobileNetV2.mlmodel",
        .mobilenetV2: "https://ml-assets.apple.com/coreml/models/Image/ImageClassification/MobileNetV2/MobileNetV2FP16.mlmodel"
    ]
    
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.aiphotokey.modelmanager", qos: .userInitiated)
    
    public init() {
        print("ModelManager initialized")
        loadDownloadedModelsList()
    }
    
    nonisolated private var modelsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let modelDir = appSupport.appendingPathComponent("AIPhotoKey/Models", isDirectory: true)
        try? fileManager.createDirectory(at: modelDir, withIntermediateDirectories: true)
        return modelDir
    }
    
    nonisolated private func modelPath(for model: AIModel) -> URL {
        return modelsDirectory.appendingPathComponent("\(model.rawValue).mlmodelc")
    }
    
    private func loadDownloadedModelsList() {
        Task {
            let models = Set(AIModel.allCases.filter { self.isModelDownloaded($0) })
            self.downloadedModels = models
        }
    }
    
    public func isModelDownloaded(_ model: AIModel) -> Bool {
        return fileManager.fileExists(atPath: modelPath(for: model).path)
    }
    
    public func downloadModel(_ aiModel: AIModel) async throws {
        guard let modelURL = modelURLs[aiModel] else {
            throw ModelError.modelNotAvailable
        }
        
        let destinationURL = modelPath(for: aiModel)
        
        // Check if model is already downloaded
        if isModelDownloaded(aiModel) {
            print("Model already downloaded: \(aiModel.rawValue)")
            return
        }
        
        print("Downloading model: \(aiModel.rawValue)")
        
        // Create a temporary file for downloading
        let tempURL = modelsDirectory.appendingPathComponent("\(aiModel.rawValue).downloading")
        
        do {
            let (downloadURL, _) = try await URLSession.shared.download(from: URL(string: modelURL)!)
            try fileManager.moveItem(at: downloadURL, to: tempURL)
            
            // Compile the model
            print("Compiling model: \(aiModel.rawValue)")
            let compiledURL = try await MLModel.compileModel(at: tempURL)
            
            // Load the compiled model with configuration
            let config = MLModelConfiguration()
            config.computeUnits = .all
            let _ = try MLModel(contentsOf: compiledURL, configuration: config)
            
            // If destination exists, remove it first
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Move to final location
            try fileManager.moveItem(at: compiledURL, to: destinationURL)
            try fileManager.removeItem(at: tempURL)
            
            downloadedModels.insert(aiModel)
            
            print("Model downloaded and compiled: \(aiModel.rawValue)")
        } catch {
            print("Error downloading/compiling model: \(error)")
            try? fileManager.removeItem(at: tempURL)
            throw error
        }
    }
    
    public func deleteModel(_ aiModel: AIModel) async throws {
        let modelURL = modelPath(for: aiModel)
        
        if fileManager.fileExists(atPath: modelURL.path) {
            try fileManager.removeItem(at: modelURL)
            downloadedModels.remove(aiModel)
            print("Model deleted: \(aiModel.rawValue)")
        }
    }
    
    nonisolated public func loadModel(_ aiModel: AIModel) throws -> VNCoreMLModel {
        let modelURL = modelPath(for: aiModel)
        
        guard fileManager.fileExists(atPath: modelURL.path) else {
            throw ModelError.modelNotDownloaded
        }
        
        let config = MLModelConfiguration()
        config.computeUnits = .all
        
        let model = try MLModel(contentsOf: modelURL, configuration: config)
        return try VNCoreMLModel(for: model)
    }
}

enum ModelError: Error {
    case modelNotAvailable
    case modelNotDownloaded
    case downloadFailed
    case compilationFailed
}
