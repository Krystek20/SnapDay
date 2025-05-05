import SwiftUI

public struct MaxHeightPreferenceKey: PreferenceKey {
  public static var defaultValue: CGFloat = .zero
  public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}
