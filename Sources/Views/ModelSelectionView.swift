import SwiftUI

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
