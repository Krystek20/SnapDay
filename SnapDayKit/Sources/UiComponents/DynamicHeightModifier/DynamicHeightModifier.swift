import SwiftUI

public extension View {
  func maxDynamic(height: Binding<CGFloat>, minHeight: CGFloat = .zero) -> some View {
    modifier(DynamicHeightModifier(height: height, minHeight: minHeight))
  }
}

private struct DynamicHeightModifier: ViewModifier {

  // MARK: - Properties

  @Binding var height: CGFloat
  var minHeight: CGFloat

  // MARK: - ViewModifier

  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { proxy in
          Color.clear.preference(key: MaxHeightPreferenceKey.self, value: proxy.size.height)
        }
      )
      .onPreferenceChange(MaxHeightPreferenceKey.self) { value in
        height = max(height, value)
      }
      .frame(height: max(height, minHeight))
  }
}
