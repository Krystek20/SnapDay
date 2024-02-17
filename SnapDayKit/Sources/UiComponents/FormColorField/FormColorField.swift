import SwiftUI
import Resources

public struct FormColorField: View {

  // MARK: - Properties

  private let title: String
  @Binding private var color: Color

  // MARK: - Initialization

  public init(title: String, color: Binding<Color>) {
    self.title = title
    self._color = color
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .leading, spacing: 7.0) {
      Text(title)
        .formTitleTextStyle
      color
        .frame(width: 60.0, height: 25.0, alignment: .center)
        .clipShape(RoundedRectangle(cornerRadius: 4.0))
        .overlay(
          ColorPicker("", selection: $color, supportsOpacity: false)
            .labelsHidden()
            .opacity(0.015)
        )
    }
    .maxWidth()
    .formBackgroundModifier()
  }
}
