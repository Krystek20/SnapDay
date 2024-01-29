import SwiftUI
import Resources

public protocol InformationViewConfigurable {
  var title: String { get }
  var subtitle: String { get }
}

public struct InformationView: View {

  // MARK: - Properties

  public let configuration: InformationViewConfigurable

  // MARK: - Initialization

  public init(configuration: InformationViewConfigurable) {
    self.configuration = configuration
  }

  // MARK: - Views

  public var body: some View {
    VStack(spacing: 5.0) {
      Text(configuration.title)
        .font(Fonts.Quicksand.bold.swiftUIFont(size: 16.0))
        .foregroundStyle(Colors.slateHaze.swiftUIColor)
      Text(configuration.subtitle)
        .font(Fonts.Quicksand.medium.swiftUIFont(size: 14.0))
        .foregroundStyle(Colors.slateHaze.swiftUIColor)
        .multilineTextAlignment(.center)
    }
    .maxWidth(alignment: .center)
    .formBackgroundModifier
  }
}
