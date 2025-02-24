import SwiftUI
import Models

public struct ModelSelectionWindow: View {
    @Binding var selectedAIModel: AIModel
    @Environment(\.dismiss) private var dismiss
    @State private var downloadingAIModels: Set<AIModel> = []
    
    public init(selectedAIModel: Binding<AIModel>) {
        self._selectedAIModel = selectedAIModel
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
                    ForEach(AIModel.allCases, id: \.self) { aiModel in
                        ModelCard(
                            aiModel: aiModel,
                            isSelected: aiModel == selectedAIModel,
                            isDownloading: downloadingAIModels.contains(aiModel),
                            onSelect: {
                                selectedAIModel = aiModel
                                dismiss()
                            },
                            onDownload: {
                                // TODO: Implement model download
                                downloadingAIModels.insert(aiModel)
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

#Preview {
    ModelSelectionWindow(selectedAIModel: .constant(.mobilenetV1))
}
