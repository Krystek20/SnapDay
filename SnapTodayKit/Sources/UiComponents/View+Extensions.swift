import SwiftUI

extension View {
  public func maxFrame() -> some View {
    frame(
      minWidth: .zero,
      maxWidth: .infinity,
      minHeight: .zero,
      maxHeight: .infinity,
      alignment: .topLeading
    )
  }

  public func maxWidth() -> some View {
    frame(
      minWidth: .zero,
      maxWidth: .infinity,
      alignment: .topLeading
    )
  }
}
