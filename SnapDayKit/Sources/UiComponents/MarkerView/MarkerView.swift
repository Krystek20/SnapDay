import SwiftUI
import Models
import Resources

public struct MarkerView<Marker: MarkerProtocol>: View {

  // MARK: - Properties

  private let marker: Marker

  // MARK: - Initialization

  public init(marker: Marker) {
    self.marker = marker
  }

  // MARK: - Views

  public var body: some View {
    Text(marker.name)
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
    marker.rgbColor.isLight()
    ? Color.sectionText
    : Color.pureWhite
  }

  private var tagBackground: some View {
    marker.rgbColor.color
      .clipShape(RoundedRectangle(cornerRadius: 3.0))
  }
}
