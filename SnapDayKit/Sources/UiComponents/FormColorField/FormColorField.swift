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
    HStack(alignment: .center) {
      Text(title)
        .formTitleTextStyle
      Spacer()
      ColorPicker("", selection: $color, supportsOpacity: false)
        .labelsHidden()
    }
    .maxWidth()
    .formBackgroundModifier()
  }
}
