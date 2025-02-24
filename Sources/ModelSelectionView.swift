import SwiftUI
import Models

public struct ModelSelectionView: View {
    @Binding var selectedModel: AIModel
    @StateObject private var modelManager = ModelManager.shared
    
    public init(selectedModel: Binding<AIModel>) {
        self._selectedModel = selectedModel
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Text("Model:")
                .font(.headline)
            Picker("", selection: $selectedModel) {
                ForEach([AIModel.mobilenetV1], id: \.self) { model in
                    Text(model.name)
                }
            }
            .frame(width: 200)
            
            if let progress = modelManager.downloadProgress[selectedModel] {
                ProgressView(value: progress)
                    .frame(width: 100)
                Button("Cancel") {
                    modelManager.cancelDownload(selectedModel)
                }
            } else if !modelManager.isDownloaded(selectedModel) {
                Button("Download") {
                    modelManager.download(selectedModel)
                }
            }
        }
    }
}

struct ModelSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModelSelectionView(selectedModel: .constant(.mobilenetV1))
            .padding()
            .frame(width: 400, height: 100)
    }
}
