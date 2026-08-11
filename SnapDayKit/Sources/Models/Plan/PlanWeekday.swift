import Foundation

public enum PlanWeekday: Int, CaseIterable, Equatable, Hashable, Identifiable {
  case sunday = 1
  case monday
  case tuesday
  case wednesday
  case thursday
  case friday
  case saturday

  public var id: Self { self }

  public var title: String {
    title(using: .autoupdatingCurrent)
  }

  public func title(using calendar: Calendar) -> String {
    calendar.standaloneWeekdaySymbols[rawValue - 1]
  }

  public static func ordered(using calendar: Calendar) -> [Self] {
    let rawValues = Array(1...7)
    let firstIndex = max(0, min(6, calendar.firstWeekday - 1))
    return (rawValues[firstIndex...] + rawValues[..<firstIndex]).compactMap(Self.init(rawValue:))
  }
}
