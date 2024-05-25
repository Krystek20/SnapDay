import Foundation
import Dependencies
import Models

public struct DayActivityRepository {
  public var activity: @Sendable (String) async throws -> DayActivity?
  public var activityTask: @Sendable (String) async throws -> DayActivityTask?
  public var saveActivity: @Sendable (DayActivity) async throws -> ()
  public var saveActivityTask: @Sendable (DayActivityTask) async throws -> ()
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
      activity: { dayActivityId in
        try await EntityHandler().fetch(
          objectType: DayActivity.self,
          predicates: [
            NSPredicate(format: "identifier == %@", dayActivityId)
          ]
        )
      },
      activityTask: { dayActivityTaskId in
        try await EntityHandler().fetch(
          objectType: DayActivityTask.self,
          predicates: [
            NSPredicate(format: "identifier == %@", dayActivityTaskId)
          ]
        )
      },
      saveActivity: { dayActivity in
        try await EntityHandler().save(dayActivity)
      },
      saveActivityTask: { dayActivityTask in
        try await EntityHandler().save(dayActivityTask)
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
