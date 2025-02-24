import SwiftUI

public struct ModelSelectionWindow: View {
    @Binding var selectedModel: AIModel
    @Environment(\.dismiss) private var dismiss
    @State private var downloadingModels: Set<AIModel> = []
    
    public init(selectedModel: Binding<AIModel>) {
        self._selectedModel = selectedModel
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Select AI Model")
                .font(.title2)
                .padding(.top)
            
            // Model List
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(AIModel.allCases, id: \.self) { model in
                        ModelCard(
                            model: model,
                            isSelected: model == selectedModel,
                            isDownloading: downloadingModels.contains(model),
                            onSelect: {
                                selectedModel = model
                                dismiss()
                            },
                            onDownload: {
                                // TODO: Implement model download
                                downloadingModels.insert(model)
                            }
                        )
                    }
                }
                .padding()
            }
            
            // Close button
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            .padding(.bottom)
        }
        .frame(width: 500, height: 600)
    }
}

private struct ModelCard: View {
    let model: AIModel
    let isSelected: Bool
    let isDownloading: Bool
    let onSelect: () -> Void
    let onDownload: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and selection
            HStack {
                Text(model.rawValue)
                    .font(.headline)
                
                Spacer()
                
                if isSelected {
                    Text("Selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Description
            Text(model.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Capabilities
            HStack(spacing: 12) {
                // License
                HStack {
                    Image(systemName: "doc.text")
                    Text(model.license)
                }
                .font(.caption2)
                
                Divider()
                
                // Object types
                HStack {
                    Image(systemName: "cube")
                    Text("\(model.capabilities.objectTypes) objects")
                }
                .font(.caption2)
                
                if model.capabilities.hasBoundingBoxes {
                    HStack {
                        Image(systemName: "rectangle.dashed")
                        Text("Boxes")
                    }
                    .font(.caption2)
                }
                
                if model.capabilities.supportsRealTime {
                    HStack {
                        Image(systemName: "bolt")
                        Text("Real-time")
                    }
                    .font(.caption2)
                }
            }
            .foregroundStyle(.secondary)
            
            // Size and actions
            HStack {
                Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(model.modelSize), countStyle: .file))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if isDownloading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("Download") {
                        onDownload()
                    }
                    .controlSize(.small)
                }
                
                Button("Select") {
                    onSelect()
                }
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.textBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    ModelSelectionWindow(selectedModel: .constant(.mobilenetV2))
}
