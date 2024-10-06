import SwiftUI

public extension View {
  func extractSize(in size: Binding<CGSize>) -> some View {
    modifier(SizeCalculator(size: size))
  }
}

struct SizeCalculator: ViewModifier {

  // MARK: - Properties

  @Binding var size: CGSize

  // MARK: - ViewModifier

  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { proxy in
          Color.clear
            .onAppear {
              size = proxy.size
            }
        }
      )
  }
}
