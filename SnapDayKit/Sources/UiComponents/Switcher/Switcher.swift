import SwiftUI
import Resources

public struct Switcher: View {

  // MARK: - Properties

  private let title: String
  private let leftArrowAction: () -> Void
  private let rightArrowAction: () -> Void

  // MARK: - Initialization

  public init(
    title: String,
    leftArrowAction: @escaping () -> Void,
    rightArrowAction: @escaping () -> Void
  ) {
    self.title = title
    self.leftArrowAction = leftArrowAction
    self.rightArrowAction = rightArrowAction
  }

  // MARK: - Views

  public var body: some View {
    VStack(spacing: .zero) {
      Divider()
      HStack(spacing: 10.0) {
        Button(
          action: leftArrowAction,
          label: {
            Image(systemName: "arrow.left.circle.fill")
              .foregroundStyle(Color.actionBlue)
          }
        )
        .padding(.leading, 30.0)
        Spacer()
        Text(title)
          .font(.system(size: 14.0, weight: .regular))
          .foregroundStyle(Color.standardText)
        Spacer()
        Button(
          action: rightArrowAction,
          label: {
            Image(systemName: "arrow.right.circle.fill")
              .foregroundStyle(Color.actionBlue)
          }
        )
        .padding(.trailing, 30.0)
      }
      .frame(height: 50.0)
      .background(
        Color.formBackground
          .shadow(color: Color.standardText.opacity(0.15), radius: 5.0, x: .zero, y: .zero)
      )
    }
  }
}
