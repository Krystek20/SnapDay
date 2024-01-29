import SwiftUI

public extension View {
  func adjustHeight(height: CGFloat = .zero, maxHeight: CGFloat? = nil) -> some View {
    modifier(HeightAdjustingModifier(height: height, maxHeight: maxHeight))
  }
}

private struct HeightAdjustingModifier: ViewModifier {

  // MARK: - Properties

  @State var height: CGFloat
  let maxHeight: CGFloat?

  // MARK: - ViewModifier

  func body(content: Content) -> some View {
    content
      .onPreferenceChange(HeightPreferenceKey.self) { value in
        self.height = value
      }
      .frame(height: min(height, maxHeight ?? height))
  }
}
