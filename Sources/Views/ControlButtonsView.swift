import SwiftUI

public enum ScanState {
    case notStarted
    case scanning
    case paused
    case completed
    
    var buttonTitle: String {
        switch self {
        case .notStarted: return "Scan"
        case .scanning: return "Pause"
        case .paused: return "Resume"
        case .completed: return "Scan Again"
        }
    }
}

public struct ControlButtonsView: View {
    @Binding var scanState: ScanState
    var onClearDatabase: () -> Void
    var onScanComplete: (() -> Void)?
    
    public init(scanState: Binding<ScanState>, onClearDatabase: @escaping () -> Void, onScanComplete: (() -> Void)? = nil) {
        self._scanState = scanState
        self.onClearDatabase = onClearDatabase
        self.onScanComplete = onScanComplete
    }
    
    public var body: some View {
        HStack(spacing: 20) {
            Button("Clear Database") {
                onClearDatabase()
                scanState = .notStarted
            }
            .tint(.red)
            
            Button(scanState.buttonTitle) {
                switch scanState {
                case .notStarted:
                    scanState = .scanning
                case .scanning:
                    scanState = .paused
                case .paused:
                    scanState = .scanning
                case .completed:
                    scanState = .notStarted
                }
            }
            .tint(scanState == .scanning ? .orange : scanState == .completed ? .green : .blue)
            .onAppear {
                if scanState == .completed {
                    onScanComplete?()
                }
            }
        }
    }
}

struct ControlButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        ControlButtonsView(scanState: .constant(.notStarted), onClearDatabase: {
            print("Clear database")
        }, onScanComplete: {
            print("Scan complete")
        })
        .padding()
        .frame(width: 400)
    }
}
