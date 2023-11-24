import Models
import UiComponents

extension MonthlySchedule: CaseIterable {
  public static var allCases: [MonthlySchedule] {
    [
      .monthlySpecificDate([]),
      .weekdayOrdinal([]),
      .firstDay,
      .secondDay,
      .midMonth,
      .lastDay,
      .secondToLastDay
    ]
  }
}

extension MonthlySchedule: Optionable {
  public var name: String {
    switch self {
    case .monthlySpecificDate:
      String(localized: "Monthly specific date", bundle: .module)
    case .weekdayOrdinal:
      String(localized: "Specific weekday", bundle: .module)
    case .firstDay:
      String(localized: "First day", bundle: .module)
    case .secondDay:
      String(localized: "Second day", bundle: .module)
    case .midMonth:
      String(localized: "Mid month", bundle: .module)
    case .lastDay:
      String(localized: "Last day", bundle: .module)
    case .secondToLastDay:
      String(localized: "Second to last day", bundle: .module)
    }
  }
}
