import SwiftUI
import Resources

public protocol InformationViewConfigurable {
  var title: String { get }
  var subtitle: String { get }
  var images: Images { get }
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
    HStack(spacing: 10.0) {
      Image(from: configuration.images)
        .resizable()
        .frame(width: 75.0, height: 75.0)

      VStack(alignment: .leading, spacing: 5.0) {
        Text(configuration.title)
          .font(.system(size: 14.0, weight: .medium))
          .foregroundStyle(Color.standardText)
        Text(configuration.subtitle)
          .font(.system(size: 12.0, weight: .regular))
          .foregroundStyle(Color.standardText)
          .multilineTextAlignment(.leading)
      }
    }

    .maxWidth(alignment: .center)
    .formBackgroundModifier()
  }
}
