import Foundation
import Models
import Dependencies

public struct TimePeriodsProvider {
  public var timePerdiods: @Sendable (_ date: Date) async throws -> [TimePeriod]
  public var timePeriod: @Sendable (_ period: Period, _ date: Date, _ shift: Int) async throws -> TimePeriod
}

extension DependencyValues {
  public var timePeriodsProvider: TimePeriodsProvider {
    get { self[TimePeriodsProvider.self] }
    set { self[TimePeriodsProvider.self] = newValue }
  }
}

extension TimePeriodsProvider: DependencyKey {
  public static var liveValue: TimePeriodsProvider {
    TimePeriodsProvider(
      timePerdiods: { date in
        try await TimePeriodsService().timePerdiods(date: date)
      },
      timePeriod: { period, date, shift in
        try await TimePeriodsService().timePeriod(from: period, date: date, shift: shift)
      }
    )
  }

  public static var previewValue: TimePeriodsProvider {
    TimePeriodsProvider(
      timePerdiods: { _ in [] },
      timePeriod: { _, _, _ in
        TimePeriod(
          id: UUID(),
          days: [],
          name: "Time Period",
          type: .day,
          dateRange: Date()...Date()
        )
      }
    )
  }
}
