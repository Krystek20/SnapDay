import Models

extension WeekdayOrdinal.Position: Optionable {
  public var name: String {
    switch self {
    case .first:
      String(localized: "First", bundle: .module)
    case .second:
      String(localized: "Second", bundle: .module)
    case .third:
      String(localized: "Third", bundle: .module)
    case .fourth:
      String(localized: "Fourth", bundle: .module)
    case .secondToLastDay:
      String(localized: "Second to last", bundle: .module)
    case .last:
      String(localized: "Last", bundle: .module)
    }
  }
}
