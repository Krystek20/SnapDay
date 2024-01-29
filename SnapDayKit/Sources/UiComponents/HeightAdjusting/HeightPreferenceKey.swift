import SwiftUI

public struct HeightPreferenceKey: PreferenceKey {
  public static var defaultValue: CGFloat = .zero
  public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value += nextValue()
  }
}
