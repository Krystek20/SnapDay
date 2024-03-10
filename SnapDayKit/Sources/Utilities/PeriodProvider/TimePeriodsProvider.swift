import Foundation
import Models
import Dependencies

public struct TimePeriodsProvider {
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
      timePeriod: { period, date, shift in
        try await TimePeriodsService().timePeriod(from: period, date: date, shift: shift)
      }
    )
  }

  public static var previewValue: TimePeriodsProvider {
    TimePeriodsProvider(
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
