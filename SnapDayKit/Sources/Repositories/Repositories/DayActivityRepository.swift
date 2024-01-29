import Foundation
import Dependencies
import Models

public struct DayActivityRepository {
  public var saveActivity: @Sendable (DayActivity) async throws -> ()
}

extension DependencyValues {
  public var dayActivityRepository: DayActivityRepository {
    get { self[DayActivityRepository.self] }
    set { self[DayActivityRepository.self] = newValue }
  }
}

extension DayActivityRepository: DependencyKey {
  public static var liveValue: DayActivityRepository {
    DayActivityRepository(
      saveActivity: { dayActivity in
        try await EntityHandler().save(dayActivity)
      }
    )
  }

  public static var previewValue: DayActivityRepository {
    DayActivityRepository(
      saveActivity: { dayActivity in
        try await EntityHandler().save(dayActivity)
      }
    )
  }
}
