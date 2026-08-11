import SwiftUI
import Resources

public struct Switcher: View {

  // MARK: - Properties

  private let title: String
  private let titleAction: (() -> Void)?
  private let leftArrowAction: () -> Void
  private let rightArrowAction: () -> Void

  // MARK: - Initialization

  public init(
    title: String,
    titleAction: (() -> Void)? = nil,
    leftArrowAction: @escaping () -> Void,
    rightArrowAction: @escaping () -> Void
  ) {
    self.title = title
    self.titleAction = titleAction
    self.leftArrowAction = leftArrowAction
    self.rightArrowAction = rightArrowAction
  }

  // MARK: - Views

  public var body: some View {
    HStack(spacing: 10.0) {
      navigationButton(systemImage: "chevron.left", action: leftArrowAction)

      Spacer(minLength: .zero)

      titleView

      Spacer(minLength: .zero)

      navigationButton(systemImage: "chevron.right", action: rightArrowAction)
    }
    .padding(.horizontal, 15.0)
    .frame(height: 50.0)
    .background(.ultraThinMaterial)
    .overlay(alignment: .bottom) {
      Divider()
        .overlay(Color.primaryText.opacity(0.08))
    }
  }

  @ViewBuilder
  private var titleView: some View {
    if let titleAction {
      Button(action: titleAction) {
        HStack(spacing: 5.0) {
          titleText
          Image(systemName: "chevron.down")
            .font(.system(size: 10.0, weight: .semibold))
            .foregroundStyle(Color.secondaryText)
        }
      }
      .buttonStyle(.plain)
    } else {
      titleText
    }
  }

  private var titleText: some View {
    Text(title)
      .font(.system(size: 15.0, weight: .medium))
      .foregroundStyle(Color.primaryText)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
  }

  private func navigationButton(
    systemImage: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: systemImage)
        .font(.system(size: 16.0, weight: .semibold))
        .foregroundStyle(Color.actionBlue)
        .frame(width: 44.0, height: 44.0)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
