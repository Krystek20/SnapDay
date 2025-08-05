import Foundation
import UiComponents
import Resources

enum InformationViewConfiguration {
  case addFriends
  case generatingUrl
}

extension InformationViewConfiguration: InformationViewConfigurable {

  var images: Images {
    switch self {
    case .addFriends:
      .emptyCollaboration
    case .generatingUrl:
      .generatingUrl
    }
  }

  var title: String {
    switch self {
    case .addFriends:
      String(localized: "No Collaborators Yet", bundle: .module)
    case .generatingUrl:
      String(localized: "Preparing your invite link…", bundle: .module)
    }
  }

  var subtitle: String {
    switch self {
    case .addFriends:
      String(localized: "Invite friends to collaborate on your boards and share activities.", bundle: .module)
    case .generatingUrl:
      String(localized: "Hang tight! We're generating your private collaboration link. Once it's ready, send it to your invitee to get started.", bundle: .module)
    }
  }
}
