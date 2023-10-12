import SwiftUI
import Resources

public struct OptionsView<Option: Optionable>: View {

  // MARK: - Properties

  private let options: [Option]
  private let highlighted: Option
  private let selected: (Option) -> Void

  // MARK: - Initialization

  public init(
    options: [Option],
    highlighted: Option,
    selected: @escaping (Option) -> Void
  ) {
    self.options = options
    self.highlighted = highlighted
    self.selected = selected
  }

  // MARK: - Views

  public var body: some View {
    HStack(spacing: 5.0) {
      ForEach(options) { option in
        Text(option.name)
          .padding(
            EdgeInsets(
              top: 5.0,
              leading: 20.0,
              bottom: 5.0,
              trailing: 20.0
            )
          )
          .onTapGesture {
            selected(option)
          }
          .font(Fonts.Quicksand.semiBold.swiftUIFont(size: 14.0))
          .foregroundStyle(
            foregroundColor(for: option)
          )
          .background(
            backgroundColor(for: option)
              .cornerRadius(15.0)
          )
      }
    }
  }

  private func backgroundColor(for option: Option) -> Color {
    guard option == highlighted else {
      return .clear
    }
    return Colors.lavenderBliss.swiftUIColor
  }

  private func foregroundColor(for option: Option) -> Color {
    guard option == highlighted else {
      return Colors.slateHaze.swiftUIColor
    }
    return Colors.whisperingSky.swiftUIColor
  }
}
