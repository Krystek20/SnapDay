import SwiftUI
import Models
import Resources

public struct TagView: View {

  // MARK: - Properties

  private let tag: Tag

  // MARK: - Initialization

  public init(tag: Tag) {
    self.tag = tag
  }

  // MARK: - Views

  public var body: some View {
    Text(tag.name)
      .padding(
        EdgeInsets(
          top: 2.0,
          leading: 5.0,
          bottom: 2.0,
          trailing: 5.0
        )
      )
      .font(.system(size: 14.0, weight: .semibold))
      .foregroundStyle(tagForegroundStyle)
      .background(tagBackground)
  }

  // MARK: - Private

  private var tagForegroundStyle: some ShapeStyle {
    tag.rgbColor.isLight()
    ? Colors.slateHaze.swiftUIColor
    : Colors.pureWhite.swiftUIColor
  }

  private var tagBackground: some View {
    tag.rgbColor.color
      .clipShape(RoundedRectangle(cornerRadius: 3.0))
  }
}
