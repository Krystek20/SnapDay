import Foundation
import UiComponents
import Resources

enum InformationViewConfiguration {
  case addFriends
}

extension InformationViewConfiguration: InformationViewConfigurable {

  var images: Images {
    switch self {
    case .addFriends:
      .emptyCollaboration
    }
  }

  var title: String {
    switch self {
    case .addFriends:
      String(localized: "No Collaborators Yet", bundle: .module)
    }
  }

  var subtitle: String {
    switch self {
    case .addFriends:
      String(localized: "Invite friends to collaborate on your boards and share activities.", bundle: .module)
    }
  }
}
