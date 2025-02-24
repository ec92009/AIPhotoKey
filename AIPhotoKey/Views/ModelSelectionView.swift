import SwiftUI
import Models

public struct ModelSelectionView: View {
    @Binding var selectedAIModel: AIModel
    @State private var showingModelSelection = false
    
    public init(selectedModel: Binding<AIModel>) {
        self._selectedAIModel = selectedModel
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Text("AI Model:")
                .font(.headline)
            
            Button {
                showingModelSelection = true
            } label: {
                HStack {
                    Text(selectedAIModel.rawValue)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                }
            }
            .sheet(isPresented: $showingModelSelection) {
                ModelSelectionWindow(selectedAIModel: $selectedAIModel)
            }
        }
    }
}

struct ModelSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModelSelectionView(selectedModel: .constant(.mobilenetV1))
            .padding()
            .frame(width: 400)
    }
}
