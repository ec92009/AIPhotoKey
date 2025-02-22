import SwiftUI

public struct ConfidenceSliderView: View {
    @Binding var confidence: Double
    
    public init(confidence: Binding<Double>) {
        self._confidence = confidence
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Text("Confidence:")
                .font(.headline)
            Slider(
                value: $confidence,
                in: 80...100,
                step: 1
            )
            .frame(width: 150)
            Text("\(Int(confidence))%")
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
    }
}

#Preview {
    ConfidenceSliderView(confidence: .constant(90))
        .padding()
}
