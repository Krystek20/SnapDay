import SwiftUI
import Resources

public extension View {
  var standard: some View {
    modifier(StandardDivider())
  }
}

private struct StandardDivider: ViewModifier {
  func body(content: Content) -> some View {
    content
      .frame(height: 1.0)
      .overlay(Color.slateHaze.opacity(0.5))
  }
}
