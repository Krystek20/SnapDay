import SwiftUI

public extension View {
  var measureHeight: some View {
    modifier(MeasureHeightModifier())
  }
}

private struct MeasureHeightModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { proxy in
          Color.clear.preference(key: HeightPreferenceKey.self, value: proxy.size.height)
        }
      )
  }
}
