import SwiftUI

public struct TitleView: View {
    public init() {}
    
    public var body: some View {
        HStack {
            Text("AIPhotoKey")
                .font(.largeTitle)
            Spacer()
            Text("v\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1.0")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 10)
    }
}

#Preview {
    TitleView()
        .padding()
}
