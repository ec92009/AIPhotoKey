import SwiftUI
import Models

public struct ModelCard: View {
    let aiModel: AIModel
    let isSelected: Bool
    let isDownloading: Bool
    let onSelect: () -> Void
    let onDownload: () -> Void
    
    public init(aiModel: AIModel, isSelected: Bool = false, isDownloading: Bool = false, onSelect: @escaping () -> Void, onDownload: @escaping () -> Void) {
        self.aiModel = aiModel
        self.isSelected = isSelected
        self.isDownloading = isDownloading
        self.onSelect = onSelect
        self.onDownload = onDownload
    }
    
    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Title and selection
                HStack {
                    Text(aiModel.rawValue)
                        .font(.headline)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                
                // Description
                Text(aiModel.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Details
                HStack(spacing: 16) {
                    // License
                    HStack {
                        Image(systemName: "doc.text")
                        Text(aiModel.license)
                    }
                    .font(.caption2)
                    
                    // Object types
                    HStack {
                        Image(systemName: "cube")
                        Text("\(aiModel.capabilities.objectTypes) objects")
                    }
                    .font(.caption2)
                    
                    if aiModel.capabilities.hasBoundingBoxes {
                        HStack {
                            Image(systemName: "rectangle.dashed")
                            Text("Boxes")
                        }
                        .font(.caption2)
                    }
                    
                    if aiModel.capabilities.supportsRealTime {
                        HStack {
                            Image(systemName: "bolt")
                            Text("Real-time")
                        }
                        .font(.caption2)
                    }
                }
                
                // Size and actions
                HStack {
                    Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(aiModel.modelSize), countStyle: .file))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if isDownloading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button(action: onDownload) {
                            Image(systemName: "arrow.down.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ModelCard(
        aiModel: .mobilenetV1,
        isSelected: true,
        isDownloading: false,
        onSelect: {},
        onDownload: {}
    )
    .padding()
    .frame(width: 400)
}
