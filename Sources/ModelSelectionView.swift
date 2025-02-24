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
}

public struct ModelSelectionView: View {
    @Binding var selectedModel: AIModel
    
    public init(selectedModel: Binding<AIModel>) {
        self._selectedModel = selectedModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
            
            if !selectedModel.description.isEmpty {
                Text(selectedModel.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ModelSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModelSelectionView(selectedModel: .constant(.mobilenetV2))
            .padding()
            .frame(width: 400, height: 100)
    }
}
