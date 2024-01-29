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
    self.label = Text(name)
      .font(Fonts.Quicksand.bold.swiftUIFont(size: 22.0))
      .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
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
    VStack(alignment: .center, spacing: 15.0) {
      HStack {
        AnyView(label)
        Spacer()
        if let rightContent = rightContent() {
          rightContent
        }
      }
      content()
    }
  }
}
