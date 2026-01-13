import Foundation
import Dependencies
import Models

public enum ActivityBy {
  case id(String)
  case name(String)
}

public struct ActivityRepository {
  public var activity: @Sendable (ActivityBy) async throws -> Activity?
  public var loadActivities: @Sendable () async throws -> [Activity]
  public var saveActivity: @Sendable (Activity) async throws -> Void
  public var deleteActivity: @Sendable (Activity) async throws -> Void
  public var activityTask: @Sendable (String) async throws -> ActivityTask?
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
      activity: { activityBy in
        let predicate: NSPredicate = switch activityBy {
        case .id(let identifier):
          NSPredicate(format: "identifier == %@", identifier as CVarArg)
        case .name(let name):
          NSPredicate(format: "name == %@", name)
        }
        return try await EntityHandler().fetch(
          Activity.self,
          predicates: { predicate }
        )
      },
      loadActivities: {
        try await EntityHandler().fetch(
          Activity.self,
          sorts: {
            NSSortDescriptor(key: "name", ascending: true)
          }
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
      activityTask: { identifier in
        try await EntityHandler().fetch(ActivityTask.self, identifier: identifier)
      },
      deleteActivityTask: { activityTask in
        try await EntityHandler().delete(activityTask)
      }
    )
  }
}

public extension ActivityRepository {
  func getActivity(identifier: String) async throws -> Activity? {
    try await activity(.id(identifier))
  }
}
