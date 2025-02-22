import SwiftUI
import AppKit

struct ContentView: View {
    @State private var photosPath: String = "~/Photos"
    @State private var selectedModel: String = "Model A"
    @State private var confidence: Double = 90
    @State private var scanState: ScanState = .notStarted
    @StateObject private var scanner = PhotoScanner()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Row 1: Title and version
            TitleView()
            
            // Row 2: Photos Source
            PhotosSourceView(photosPath: $photosPath)
            
            // Row 3: Model Selection and Confidence
            HStack(spacing: 20) {
                ModelSelectionView(selectedModel: $selectedModel)
                Spacer()
                ConfidenceSliderView(confidence: $confidence)
            }
            
            // Row 4: Control Buttons
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
                        scanner.startScan(path: photosPath)
                    }
                case .paused:
                    scanner.stopScan()
                case .completed:
                    break // No action needed, button will reset to notStarted state
                }
            }
            
            // Row 5: Results (expands vertically)
            ResultsView(photos: scanner.foundPhotos, baseDirectory: photosPath)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Row 6: Status Line
            StatusLineView(message: scanner.statusMessage)
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
