import SwiftUI

extension Image {
  public func iconable(color: Color) -> some View {
    self
      .resizable()
      .scaledToFit()
      .frame(width: 15.0, height: 15.0)
      .foregroundStyle(color)
      .imageScale(.medium)
  }
}
