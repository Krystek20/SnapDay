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
        .font(.system(size: 16.0, weight: .bold))
        .foregroundStyle(Color.sectionText)
      Text(configuration.subtitle)
        .font(.system(size: 14.0, weight: .medium))
        .foregroundStyle(Color.sectionText)
        .multilineTextAlignment(.center)
    }
    .maxWidth(alignment: .center)
    .formBackgroundModifier()
  }
}
