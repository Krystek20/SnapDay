import SwiftUI
import Resources

public extension View {
  func selectableTextItemStyle(isSelected: Bool) -> some View {
    modifier(SelectableTextItemStyle(isSelected: isSelected))
  }
}

struct SelectableTextItemStyle: ViewModifier {

  // MARK: - Properties

  let isSelected: Bool

  private let padding = EdgeInsets(
    top: 2.0,
    leading: 5.0,
    bottom: 2.0,
    trailing: 5.0
  )

  // MARK: - ViewModifier

  func body(content: Content) -> some View {
    content
      .padding(padding)
      .font(.system(size: 14.0, weight: .semibold))
      .foregroundStyle(foregroundColor)
      .background(background)
  }

  @ViewBuilder
  private var background: some View {
    if isSelected {
      Color.lavenderBliss
        .clipShape(RoundedRectangle(cornerRadius: 3.0))
    }
  }

  @ViewBuilder
  private var foregroundColor: some ShapeStyle {
    isSelected
    ? Color.pureWhite
    : Color.deepSpaceBlue
  }
}
