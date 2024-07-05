import Foundation
import Dependencies
import Models

public struct ActivitiesFetchConfiguration {
  let range: ClosedRange<Date>?
  let done: Bool?
  let predicates: [NSPredicate]

  public init(
    range: ClosedRange<Date>? = nil,
    done: Bool? = nil,
    predicates: [NSPredicate] = []
  ) {
    self.range = range
    self.done = done
    self.predicates = predicates
  }
}

public struct DayActivityRepository {
  public var activity: @Sendable (String) async throws -> DayActivity?
  public var activityTask: @Sendable (String) async throws -> DayActivityTask?
  public var activities: @Sendable (ActivitiesFetchConfiguration) async throws -> [DayActivity]
  public var saveDayActivity: @Sendable (DayActivity) async throws -> ()
  public var saveDayActivityTask: @Sendable (DayActivityTask) async throws -> ()
  public var removeDayActivity: @Sendable (DayActivity) async throws -> ()
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
      activities: { configuration in
        var predicates: [NSPredicate] = []
        if let range = configuration.range {
          predicates.append(
            NSPredicate(format: "day.date >= %@ AND day.date <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
          )
        }
        if let done = configuration.done {
          let predicate = done
          ? NSPredicate(format: "doneDate != nil")
          : NSPredicate(format: "doneDate == nil")
          predicates.append(predicate)
        }
        predicates.append(contentsOf: configuration.predicates)
        return try await EntityHandler().fetch(
          objectType: DayActivity.self,
          predicates: predicates,
          sorts: loadActivitiesSorts
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
      }
    )
  }
}

private extension DayActivityRepository {
  @SortBuilder
  static var loadActivitiesSorts: [NSSortDescriptor] {
    NSSortDescriptor(key: "name", ascending: true)
  }
}
