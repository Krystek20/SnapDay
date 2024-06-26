import SwiftUI
import Resources

public struct SectionView<Content: View, RightContent: View>: View {

  // MARK: - Properties

  private let label: any View
  @ViewBuilder private let rightContent: () -> RightContent?
  @ViewBuilder private let content: () -> Content

  // MARK: - Initialization

  public init(
    name: String,
    @ViewBuilder rightContent: @escaping () -> RightContent?,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.label = Text(name.uppercased())
      .font(.system(size: 14.0, weight: .regular))
      .foregroundStyle(Color.sectionText)
    self.rightContent = rightContent
    self.content = content
  }

  public init(
    @ViewBuilder label: () -> any View,
    @ViewBuilder rightContent: @escaping () -> RightContent,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.label = label()
    self.rightContent = rightContent
    self.content = content
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .center, spacing: 5.0) {
      HStack(alignment: .center) {
        AnyView(label)
          .padding(.leading, 5.0)
        Spacer()
        if let rightContent = rightContent() {
          rightContent
            .padding(.trailing, 5.0)
        }
      }
      content()
    }
  }
}
