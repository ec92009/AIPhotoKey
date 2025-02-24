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
    @State private var showingModelSelection = false
    
    public init(selectedModel: Binding<AIModel>) {
        self._selectedModel = selectedModel
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Text("Model:")
                .font(.headline)
            
            Button {
                showingModelSelection = true
            } label: {
                HStack {
                    Text(selectedModel.rawValue)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                }
            }
            .sheet(isPresented: $showingModelSelection) {
                ModelSelectionWindow(selectedModel: $selectedModel)
            }
        }
    }
}

struct ModelSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModelSelectionView(selectedModel: .constant(.mobilenetV2))
            .padding()
            .frame(width: 400)
    }
}
