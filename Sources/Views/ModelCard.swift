import SwiftUI
import Models

public struct ModelCard: View {
    let model: AIModel
    let isDownloading: Bool
    let onSelect: () -> Void
    
    public init(model: AIModel, isDownloading: Bool = false, onSelect: @escaping () -> Void) {
        self.model = model
        self.isDownloading = isDownloading
        self.onSelect = onSelect
    }
    
    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Title and capabilities
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.rawValue)
                        .font(.headline)
                    
                    Text("\(model.capabilities.objectTypes) object types")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Description
                Text(model.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                
                // Size and actions
                HStack {
                    Text("Size: \(Int64(model.modelSize).formattedFileSize)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if isDownloading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.background)
                    .strokeBorder(.secondary.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
