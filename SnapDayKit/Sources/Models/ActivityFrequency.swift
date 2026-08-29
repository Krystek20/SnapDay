public enum ActivityFrequency: Equatable, Hashable, Codable {
  case daily
  case weekly(days: [Int])
  case biweekly(days: [Int], startWeek: BiweeklyStartWeek)
  case monthly(monthlySchedule: MonthlySchedule)
}

public extension ActivityFrequency {
  var requiresPremiumAccess: Bool {
    switch self {
    case .daily, .weekly:
      false
    case .biweekly, .monthly:
      true
    }
  }
}

public enum BiweeklyStartWeek: Equatable, Hashable, Codable {
  case current
  case next
}
