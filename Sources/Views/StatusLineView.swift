import SwiftUI

public struct StatusLineView: View {
    let message: String
    let progress: Double?
    
    public init(message: String = "Ready", progress: Double? = nil) {
        self.message = message
        self.progress = progress
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Text(message)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
            
            if let progress {
                Spacer()
                ProgressView(value: progress, total: 1.0)
                    .frame(width: 100)
            }
        }
        .frame(height: 24)
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusLineView()
        StatusLineView(message: "Downloading model...")
        StatusLineView(message: "Processing photos: 45/100", progress: 0.45)
    }
    .padding()
}
