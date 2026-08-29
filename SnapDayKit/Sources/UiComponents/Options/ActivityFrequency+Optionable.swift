import Models

extension ActivityFrequency: Optionable, CaseIterable {

  public var name: String {
    switch self {
    case .daily:
      String(localized: "Daily", bundle: .module)
    case .weekly:
      String(localized: "Weekly", bundle: .module)
    case .biweekly:
      String(localized: "Biweekly · Plus", bundle: .module)
    case .monthly:
      String(localized: "Monthly · Plus", bundle: .module)
    }
  }

  public static var allCases: [ActivityFrequency] {
    [
      .daily,
      .weekly(days: []),
      .biweekly(days: [], startWeek: .current),
      .monthly(monthlySchedule: .monthlySpecificDate([]))
    ]
  }
}
