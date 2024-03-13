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
        .font(.system(size: 14.0, weight: .medium))
        .foregroundStyle(Color.standardText)
      Text(configuration.subtitle)
        .font(.system(size: 12.0, weight: .regular))
        .foregroundStyle(Color.standardText)
        .multilineTextAlignment(.center)
    }
    .maxWidth(alignment: .center)
    .formBackgroundModifier()
  }
}
