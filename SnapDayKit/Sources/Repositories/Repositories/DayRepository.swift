import Foundation
import Dependencies
import Models

public struct DayRepository {
  public var loadDays: @Sendable (_ dateRange: ClosedRange<Date>) async throws -> [Day]
  public var loadDay: @Sendable (_ date: Date) async throws -> Day?
  public var saveDay: @Sendable (_ day: Day) async throws -> ()
}

extension DependencyValues {
  public var dayRepository: DayRepository {
    get { self[DayRepository.self] }
    set { self[DayRepository.self] = newValue }
  }
}

extension DayRepository: DependencyKey {
  public static var liveValue: DayRepository {
    DayRepository(
      loadDays: { dateRange in
        try await EntityHandler().fetch(Day.self) {
          NSPredicate(format: "date >= %@ AND date <= %@", dateRange.lowerBound as CVarArg, dateRange.upperBound as CVarArg)
        }
      },
      loadDay: { date in
        try await EntityHandler().fetch(Day.self) {
          NSPredicate(format: "date == %@", date as CVarArg)
        }
      },
      saveDay: { days in
        try await EntityHandler().save(days)
      }
    )
  }

  public static var previewValue: DayRepository {
    DayRepository(
      loadDays: { _ in [] },
      loadDay: { _ in nil },
      saveDay: { _ in }
    )
  }
}
