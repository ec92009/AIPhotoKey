import SwiftUI
import AppKit
import Models

struct ContentView: View {
    @StateObject private var sessionPrefs = SessionPreferences.shared
    @StateObject private var modelManager = ModelManager()
    @State private var scanState: ScanState = .notStarted
    @StateObject private var scanner: PhotoScanner
    
    init() {
        print("ContentView initializing...")
        let modelManager = ModelManager()
        _scanner = StateObject(wrappedValue: PhotoScanner(modelManager: modelManager))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Row 1: Title and version
            TitleView()
            
            // Row 3: Photos Source
            PhotosSourceView(photosPath: $sessionPrefs.photosSourceFolder)
            
            // Row 4: Model Selection and Confidence
            HStack(spacing: 20) {
                ModelSelectionView(selectedModel: $sessionPrefs.aiModelChoice)
                    .onChange(of: sessionPrefs.aiModelChoice) { newModel in
                        // Check if model needs to be downloaded
                        if !modelManager.downloadedModels.contains(newModel) {
                            Task {
                                do {
                                    try await modelManager.downloadModel(newModel)
                                } catch {
                                    print("Failed to download model: \(error)")
                                }
                            }
                        }
                    }
                Spacer()
                ConfidenceSliderView(confidence: $sessionPrefs.confidenceSetting)
            }
            
            // Row 5: Control Buttons
            ControlButtonsView(scanState: $scanState) {
                scanner.clearDatabase()
            }
            .onChange(of: scanState) { newState in
                switch newState {
                case .notStarted:
                    break
                case .scanning:
                    if scanner.isScanning {
                        scanner.resumeScan()
                    } else {
                        // Check if selected model is downloaded
                        if !modelManager.downloadedModels.contains(sessionPrefs.aiModelChoice) {
                            Task {
                                do {
                                    try await modelManager.downloadModel(sessionPrefs.aiModelChoice)
                                    scanner.startScan(
                                        path: sessionPrefs.photosSourceFolder,
                                        model: sessionPrefs.aiModelChoice,
                                        confidence: sessionPrefs.confidenceSetting
                                    )
                                } catch {
                                    print("Failed to download model: \(error)")
                                }
                            }
                        } else {
                            scanner.startScan(
                                path: sessionPrefs.photosSourceFolder,
                                model: sessionPrefs.aiModelChoice,
                                confidence: sessionPrefs.confidenceSetting
                            )
                        }
                    }
                case .paused:
                    scanner.pauseScan()
                case .completed:
                    break // No action needed, button will reset to notStarted state
                }
            }
            
            // Row 6: Results (expands vertically)
            ResultsView(
                baseDirectory: sessionPrefs.photosSourceFolder,
                scanner: scanner,
                modelManager: modelManager
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Row 7: Status Line
            HStack {
                Text(scanner.statusMessage)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            print("Building ContentView body")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
