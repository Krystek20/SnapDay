import SwiftUI
import Resources

public struct FormTextField<Content: View>: View {

  // MARK: - Properties

  private let title: String?
  private let placeholder: String
  private let value: Binding<String>
  @ViewBuilder private let rightContent: () -> Content

  // MARK: - Initialization

  public init(
    title: String? = nil,
    placeholder: String = "",
    value: Binding<String>,
    @ViewBuilder rightContent: @escaping () -> Content = { EmptyView() }
  ) {
    self.title = title
    self.placeholder = placeholder
    self.value = value
    self.rightContent = rightContent
  }

  // MARK: - Views

  public var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2.0) {
        if let title {
          Text(title)
            .formTitleTextStyle
        }

        TextField(placeholder, text: value)
          .font(.system(size: 16.0, weight: .regular))
          .foregroundStyle(Color.standardText)
      }

      let rightContent = rightContent()
      if rightContent is EmptyView == false {
        Spacer()
        rightContent
      }
    }
    .formBackgroundModifier()
  }
}
