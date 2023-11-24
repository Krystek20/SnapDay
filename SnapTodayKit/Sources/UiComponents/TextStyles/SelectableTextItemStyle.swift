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
      .font(Fonts.Quicksand.semiBold.swiftUIFont(size: 14.0))
      .foregroundStyle(foregroundColor)
      .background(background)
  }

  @ViewBuilder
  private var background: some View {
    if isSelected {
      Colors.lavenderBliss.swiftUIColor
        .clipShape(RoundedRectangle(cornerRadius: 3.0))
    }
  }

  @ViewBuilder
  private var foregroundColor: some ShapeStyle {
    isSelected
    ? Colors.pureWhite.swiftUIColor
    : Colors.deepSpaceBlue.swiftUIColor
  }
}
