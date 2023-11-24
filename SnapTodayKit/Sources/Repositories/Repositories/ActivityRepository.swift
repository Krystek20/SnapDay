import Foundation
import Dependencies
import Models

public struct ActivityRepository {
  public var loadActivities: @Sendable () async throws -> [Activity]
  public var saveActivity: @Sendable (Activity) async throws -> ()
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
      loadActivities: {
        try await EntityHandler().fetch(objectType: Activity.self)
      },
      saveActivity: { activity in
        try await EntityHandler().save(activity)
      }
    )
  }

  public static var previewValue: ActivityRepository {
    ActivityRepository(
      loadActivities: { [] },
      saveActivity: { _ in }
    )
  }
}
