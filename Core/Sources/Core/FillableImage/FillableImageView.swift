import SwiftUI

public struct FillableImageView: View {
    let fillIcon: String
    let unfillIcon: String
    let frame: CGFloat
    @Binding var isSelected: Bool
    
    public var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            Image(isSelected ? fillIcon : unfillIcon, bundle: .module)
                .resizable()
                .frame(width: frame, height: frame)
        }

    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isSelected = true
    FillableImageView(fillIcon: "minus", unfillIcon: "plus", frame: 20, isSelected: $isSelected)
}
