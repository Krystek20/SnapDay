import Foundation
import UiComponents
import Resources

enum InformationViewConfiguration {
  case addActivity
}

extension InformationViewConfiguration: InformationViewConfigurable {

  var images: Images {
    switch self {
    case .addActivity:
      .activityListEmpty
    }
  }

  var title: String {
    switch self {
    case .addActivity:
      String(localized: "No Saved Activities Yet", bundle: .module)
    }
  }

  var subtitle: String {
    switch self {
    case .addActivity:
      String(localized: "Easily save your favorite activities for quick access in the future.", bundle: .module)
    }
  }
}
