import Foundation
import Dependencies
import Models

public struct DayActivityRepository {
  public var saveActivity: @Sendable (DayActivity) async throws -> ()
  public var removeActivity: @Sendable (DayActivity) async throws -> ()
  public var removeDayActivityTask: @Sendable (DayActivityTask) async throws -> ()
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
      },
      removeActivity: { dayActivity in
        try await EntityHandler().delete(dayActivity)
        for dayActivityTask in dayActivity.dayActivityTasks {
          try await EntityHandler().delete(dayActivityTask)
        }
      },
      removeDayActivityTask: { dayActivityTask in
        try await EntityHandler().delete(dayActivityTask)
      }
    )
  }
}
