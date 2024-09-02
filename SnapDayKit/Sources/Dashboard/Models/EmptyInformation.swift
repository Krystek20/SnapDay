import Foundation
import UiComponents
import Resources

enum InformationViewConfiguration {
  case pastDay
  case todayOrFuture
  case todaySuccess
}

extension InformationViewConfiguration: InformationViewConfigurable {

  var images: Images {
    switch self {
    case .pastDay:
      .listEmpty
    case .todayOrFuture:
      .listEmpty
    case .todaySuccess:
      .listDone
    }
  }

  var title: String {
    switch self {
    case .pastDay:
      String(localized: "A Day of Unplanned Possibilities", bundle: .module)
    case .todayOrFuture:
      String(localized: "Your Day, Your Way!", bundle: .module)
    case .todaySuccess:
      String(localized: "Success!", bundle: .module)
    }
  }

  var subtitle: String {
    switch self {
    case .pastDay:
      String(localized: "Hope it was enjoyable!", bundle: .module)
    case .todayOrFuture:
      String(localized: "A blank canvas awaits your plans or spontaneous joys.", bundle: .module)
    case .todaySuccess:
      String(localized: "🎉 Great job! Now, take a rest and enjoy the rest of your day with a smile! 🎉", bundle: .module)
    }
  }
}
