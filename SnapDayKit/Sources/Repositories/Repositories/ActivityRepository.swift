import Foundation
import Dependencies
import Models

public struct ActivityRepository {
  public var activity: @Sendable (UUID) async throws -> Activity?
  public var loadActivities: @Sendable () async throws -> [Activity]
  public var saveActivity: @Sendable (Activity) async throws -> Void
  public var deleteActivity: @Sendable (Activity) async throws -> Void
  public var deleteActivityTask: @Sendable (ActivityTask) async throws -> Void
}

extension DependencyValues {
  public var activityRepository: ActivityRepository {
    get { self[ActivityRepository.self] }
    set { self[ActivityRepository.self] = newValue }
  }
}

extension ActivityRepository: DependencyKey {
  public static var liveValue: ActivityRepository {
    ActivityRepository(
      activity: { activityId in
        try await EntityHandler().fetch(
          objectType: Activity.self,
          predicates: [
            NSPredicate(format: "identifier == %@", activityId as CVarArg)
          ]
        )
      },
      loadActivities: {
        try await EntityHandler().fetch(
          objectType: Activity.self,
          sorts: loadActivitiesSorts
        )
      },
      saveActivity: { activity in
        try await EntityHandler().save(activity)
      },
      deleteActivity: { activity in
        try await EntityHandler().delete(activity)
        for task in activity.tasks {
          try await EntityHandler().delete(task)
        }
      },
      deleteActivityTask: { activityTask in
        try await EntityHandler().delete(activityTask)
      }
    )
  }
}

// MARK: - Helpers

private extension ActivityRepository {
  @SortBuilder
  static var loadActivitiesSorts: [NSSortDescriptor] {
    NSSortDescriptor(key: "name", ascending: true)
  }
}
