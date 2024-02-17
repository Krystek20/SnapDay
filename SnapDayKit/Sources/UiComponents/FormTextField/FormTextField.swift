import SwiftUI
import Resources

public struct FormTextField: View {

  // MARK: - Properties

  private let title: String?
  private let placeholder: String
  private let value: Binding<String>

  // MARK: - Initialization

  public init(
    title: String? = nil,
    placeholder: String = "",
    value: Binding<String>
  ) {
    self.title = title
    self.placeholder = placeholder
    self.value = value
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .leading, spacing: 2.0) {
      if let title {
        Text(title)
          .formTitleTextStyle
      }
      TextField(placeholder, text: value)
        .font(Fonts.Quicksand.medium.swiftUIFont(size: 16.0))
        .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
    }
    .formBackgroundModifier()
  }
}
