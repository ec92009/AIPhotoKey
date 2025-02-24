import SwiftUI

public enum AIModel: String, CaseIterable {
    case mobilenetV2 = "Mobilenet V2"
    case resnet50 = "Resnet 50"
    case vgg16 = "VGG 16"
    
    var description: String {
        switch self {
        case .mobilenetV2:
            return "A small, efficient model for image classification."
        case .resnet50:
            return "A medium-sized model for image classification with higher accuracy."
        case .vgg16:
            return "A large model for image classification with high accuracy."
        }
    }
    
    var license: String {
        switch self {
        case .mobilenetV2:
            return "Apache License 2.0"
        case .resnet50:
            return "MIT License"
        case .vgg16:
            return "MIT License"
        }
    }
    
    var capabilities: ModelCapabilities {
        switch self {
        case .mobilenetV2:
            return ModelCapabilities(objectTypes: 1000, hasBoundingBoxes: false, supportsRealTime: true)
        case .resnet50:
            return ModelCapabilities(objectTypes: 1000, hasBoundingBoxes: true, supportsRealTime: false)
        case .vgg16:
            return ModelCapabilities(objectTypes: 1000, hasBoundingBoxes: true, supportsRealTime: false)
        }
    }
}

public struct ModelCapabilities {
    let objectTypes: Int
    let hasBoundingBoxes: Bool
    let supportsRealTime: Bool
}

public struct ModelSelectionView: View {
    @Binding var selectedModel: AIModel
    
    public init(selectedModel: Binding<AIModel>) {
        self._selectedModel = selectedModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Model:")
                    .font(.headline)
                Picker("", selection: $selectedModel) {
                    ForEach(AIModel.allCases, id: \.self) { model in
                        Text(model.rawValue)
                            .tag(model)
                    }
                }
                .frame(width: 200)
            }
            
            // Model details
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedModel.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    // License info
                    HStack {
                        Image(systemName: "doc.text")
                        Text(selectedModel.license)
                    }
                    .font(.caption2)
                    
                    Divider()
                    
                    // Capabilities
                    HStack {
                        Image(systemName: "cube")
                        Text("\(selectedModel.capabilities.objectTypes) objects")
                    }
                    .font(.caption2)
                    
                    if selectedModel.capabilities.hasBoundingBoxes {
                        HStack {
                            Image(systemName: "rectangle.dashed")
                            Text("Boxes")
                        }
                        .font(.caption2)
                    }
                    
                    if selectedModel.capabilities.supportsRealTime {
                        HStack {
                            Image(systemName: "bolt")
                            Text("Real-time")
                        }
                        .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)
        }
    }
}

struct ModelSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModelSelectionView(selectedModel: .constant(.mobilenetV2))
            .padding()
            .frame(width: 400, height: 200)
    }
}
