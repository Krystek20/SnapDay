import Foundation
import Models
import Dependencies

public struct TimePeriodsProvider {
  public var timePerdiods: @Sendable (_ date: Date) async throws -> [TimePeriod]
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
      }
    )
  }

  public static var previewValue: TimePeriodsProvider {
    TimePeriodsProvider(
      timePerdiods: { _ in [] }
    )
  }
}
