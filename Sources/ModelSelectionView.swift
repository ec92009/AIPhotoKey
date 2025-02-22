import SwiftUI

public struct ModelSelectionView: View {
    @Binding var selectedModel: String
    let models = ["Model A", "Model B", "Model C", "Model D"]
    
    public init(selectedModel: Binding<String>) {
        self._selectedModel = selectedModel
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Text("Model:")
                .font(.headline)
            Picker("", selection: $selectedModel) {
                ForEach(models, id: \.self) { model in
                    Text(model)
                }
            }
            .frame(width: 200)
        }
    }
}

struct ModelSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModelSelectionView(selectedModel: .constant("Model A"))
            .padding()
            .frame(width: 400, height: 100)
    }
}
