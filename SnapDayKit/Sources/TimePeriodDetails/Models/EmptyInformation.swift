import UiComponents

enum EmptyDayConfiguration {
  case pastDay
  case todayOrFuture
}

extension EmptyDayConfiguration: InformationViewConfigurable {
  var title: String {
    switch self {
    case .pastDay:
      String(localized: "A Day of Unplanned Possibilities", bundle: .module)
    case .todayOrFuture:
      String(localized: "Your Day, Your Way!", bundle: .module)
    }
  }
  
  var subtitle: String {
    switch self {
    case .pastDay:
      String(localized: "Hope it was enjoyable!", bundle: .module)
    case .todayOrFuture:
      String(localized: "A blank canvas awaits your plans or spontaneous joys.", bundle: .module)
    }
  }
}
