import SwiftUI
import Resources

public enum OptionsAxis {
  case horizontal(VerticalAlignment)
  case vertical(HorizontalAlignment)
  case grid
}

public struct OptionsView<Option: Optionable>: View {

  // MARK: - Properties

  private let options: [Option]
  @Binding private var selected: Option?
  private let axis: OptionsAxis

  // MARK: - Initialization

  public init(
    options: [Option],
    selected: Binding<Option?>,
    axis: OptionsAxis = .horizontal(.center)
  ) {
    self.options = options
    self._selected = selected
    self.axis = axis
  }

  // MARK: - Views

  public var body: some View {
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
          guard selected?.name != option.name else { return }
          selected = option
        }
        .font(.system(size: 14.0, weight: .medium))
        .foregroundStyle(foregroundColor(for: option))
        .background(backgroundView(for: option))
    }
    .axis(axis)
  }

  @ViewBuilder
  private func backgroundView(for option: Option) -> some View {
    if option.name == selected?.name {
      Color.actionBlue
        .clipShape(RoundedRectangle(cornerRadius: 15.0))
    } else {
      RoundedRectangle(cornerRadius: 15.0)
        .stroke(Color.actionBlue, lineWidth: 1.0)
        .padding(1.0)
    }
  }

  private func foregroundColor(for option: Option) -> Color {
    guard option.name == selected?.name else {
      return .standardText
    }
    return .pureWhite
  }
}

private extension View {
  func axis(_ axis: OptionsAxis) -> some View {
    modifier(OptionsViewModifier(axis: axis))
  }
}

private struct OptionsViewModifier: ViewModifier {

  // MARK: - Properties

  let axis: OptionsAxis

  // MARK: - ViewModifier

  func body(content: Content) -> some View {
    switch axis {
    case .horizontal(let alignment):
      ScrollView(.horizontal) {
        HStack(alignment: alignment, spacing: 5.0) { content }
      }
    case .vertical(let alignment):
      ScrollView(.vertical) {
        VStack(alignment: alignment, spacing: 5.0) { content }
      }
    case .grid:
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
        content
      }
    }
  }
}
