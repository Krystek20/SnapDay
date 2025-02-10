import Foundation
import Dependencies
import Models

public struct ActivitiesFetchConfiguration {
  let range: ClosedRange<Date>?
  let done: Bool?
  let predicates: [NSPredicate]
  let sorts: [NSSortDescriptor]
  let fetchLimit: Int?

  public init(
    range: ClosedRange<Date>? = nil,
    done: Bool? = nil,
    predicates: [NSPredicate] = [],
    sorts: [NSSortDescriptor] = [],
    fetchLimit: Int? = nil
  ) {
    self.range = range
    self.done = done
    self.predicates = predicates
    self.sorts = sorts
    self.fetchLimit = fetchLimit
  }
}

public struct DayActivityRepository {
  public var activity: @Sendable (String) async throws -> DayActivity?
  public var activityTask: @Sendable (String) async throws -> DayActivityTask?
  public var activities: @Sendable (ActivitiesFetchConfiguration) async throws -> [DayActivity]
  public var saveDayActivity: @Sendable (DayActivity) async throws -> Void
  public var saveDayActivityTask: @Sendable (DayActivityTask) async throws -> Void
  public var removeDayActivity: @Sendable (DayActivity) async throws -> Void
  public var removeDayActivityTask: @Sendable (DayActivityTask) async throws -> Void
  public var share: @Sendable (DayActivity) async throws -> Share
  public var accept: @Sendable (Invitation) async throws -> Void
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
        try await EntityHandler().fetch(DayActivity.self, identifier: dayActivityId)
      },
      activityTask: { dayActivityTaskId in
        try await EntityHandler().fetch(DayActivityTask.self, identifier: dayActivityTaskId)
      },
      activities: { configuration in
        var predicates: [NSPredicate] = []
        if let range = configuration.range {
          predicates.append(
            NSPredicate(format: "date >= %@ AND date <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
          )
        }
        if let done = configuration.done {
          let predicate = done
          ? NSPredicate(format: "doneDate != nil")
          : NSPredicate(format: "doneDate == nil")
          predicates.append(predicate)
        }
        predicates.append(contentsOf: configuration.predicates)

        let sorts = configuration.sorts.isEmpty
        ? [NSSortDescriptor(key: "name", ascending: true)]
        : configuration.sorts

        return try await EntityHandler().fetch(
          DayActivity.self,
          predicates: { predicates },
          sorts: { sorts },
          fetchLimit: configuration.fetchLimit
        )
      },
      saveDayActivity: { dayActivity in
        try await EntityHandler().save(dayActivity)
      },
      saveDayActivityTask: { dayActivityTask in
        try await EntityHandler().save(dayActivityTask)
      },
      removeDayActivity: { dayActivity in
        try await EntityHandler().delete(dayActivity)
        for dayActivityTask in dayActivity.dayActivityTasks {
          try await EntityHandler().delete(dayActivityTask)
        }
      },
      removeDayActivityTask: { dayActivityTask in
        try await EntityHandler().delete(dayActivityTask)
      },
      share: { dayActivity in
        var thumbnailImageData: Data?
        var dependecies: [any Entity] = []
        if let iconId = dayActivity.iconId,
           let icon = try await EntityHandler().fetch(Icon.self, identifier: iconId as CVarArg) {
          thumbnailImageData = icon.data
          dependecies.append(icon)
        }
        let taskIconsIds = dayActivity.dayActivityTasks.compactMap(\.iconId)
        for taskIconId in taskIconsIds {
          guard let icon = try await EntityHandler().fetch(Icon.self, identifier: taskIconId as CVarArg) else { continue }
          dependecies.append(icon)
        }
        dependecies.append(contentsOf: dayActivity.tags)
        dependecies.append(contentsOf: dayActivity.tags.map(\.rgbColor))
        dependecies.append(contentsOf: dayActivity.labels)
        dependecies.append(contentsOf: dayActivity.labels.map(\.rgbColor))
        let share = try await EntityHandler().share(
          dayActivity,
          dependecies: dependecies,
          title: dayActivity.name,
          thumbnailImageData: thumbnailImageData
        )
        Task { @MainActor in
          ShareViewWrapper.shared.presentCloudSharingController(share: share)
        }
        return share
      },
      accept: { invitation in
        try await EntityHandler().accept(invitation: invitation)
      }
    )
  }
}
