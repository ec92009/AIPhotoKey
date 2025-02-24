import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var sessionPrefs = SessionPreferences.shared
    @State private var scanState: ScanState = .notStarted
    @StateObject private var scanner = PhotoScanner()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Row 1: Title and version
            TitleView()
            
            // Row 3: Photos Source
            PhotosSourceView(photosPath: $sessionPrefs.photosSourceFolder)
            
            // Row 4: Model Selection and Confidence
            HStack(spacing: 20) {
                ModelSelectionView(selectedModel: $sessionPrefs.modelChoice)
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
                        scanner.startScan(path: sessionPrefs.photosSourceFolder)
                    }
                case .paused:
                    scanner.stopScan()
                case .completed:
                    break // No action needed, button will reset to notStarted state
                }
            }
            
            // Row 6: Results (expands vertically)
            ResultsView(photos: scanner.foundPhotos, baseDirectory: sessionPrefs.photosSourceFolder)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Row 7: Status Line
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
