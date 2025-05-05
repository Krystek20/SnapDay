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

  private let entityHandler = EntityHandler()

  public func activity(identifier: String) async throws -> DayActivity? {
    try await entityHandler.fetch(DayActivity.self, identifier: identifier)
  }

  public func activityTask(identifier: String) async throws -> DayActivityTask? {
    try await entityHandler.fetch(DayActivityTask.self, identifier: identifier)
  }

  public func sharedDayActivity(identifier: String) async throws -> SharedDayActivity? {
    try await entityHandler.fetch(SharedDayActivity.self, identifier: identifier)
  }

  public func sharedDayActivityTask(identifier: String) async throws -> SharedDayActivityTask? {
    try await entityHandler.fetch(SharedDayActivityTask.self, identifier: identifier)
  }

  public func dayActivities(configuration: ActivitiesFetchConfiguration) async throws -> [DayActivity] {
    try await activities(configuration: configuration)
  }

  public func sharedDayActivities(configuration: ActivitiesFetchConfiguration) async throws -> [SharedDayActivity] {
    try await activities(configuration: configuration)
  }

  private func activities<T: Entity>(configuration: ActivitiesFetchConfiguration) async throws -> [T] {
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

    return try await entityHandler.fetch(
      T.self,
      predicates: { predicates },
      sorts: { sorts },
      fetchLimit: configuration.fetchLimit
    )
  }

  public func saveDayActivity(_ dayActivity: DayActivity) async throws {
    try await entityHandler.save(dayActivity)
  }

  public func saveDayActivityTask(_ dayActivityTask: DayActivityTask) async throws {
    try await entityHandler.save(dayActivityTask)
  }

  public func removeDayActivity(_ dayActivity: DayActivity) async throws {
    try await entityHandler.delete(dayActivity)
    for dayActivityTask in dayActivity.dayActivityTasks {
      try await removeDayActivityTask(dayActivityTask)
    }
  }

  public func removeDayActivityTask(_ dayActivityTask: DayActivityTask) async throws {
    try await entityHandler.delete(dayActivityTask)
  }

  public func sharedDayActivity(objectId: String) async throws -> SharedDayActivity? {
    try await activities(
      configuration: ActivitiesFetchConfiguration(
        predicates: [
          NSPredicate(format: "ANY sharedBy.objectIdentifier == %@", objectId)
        ]
      )
    ).first
  }

  public func sharedDayActivityTask(objectId: String) async throws -> SharedDayActivityTask? {
    try await activities(
      configuration: ActivitiesFetchConfiguration(
        predicates: [
          NSPredicate(format: "ANY sharedBy.objectIdentifier == %@", objectId)
        ]
      )
    ).first
  }

  public func saveSharedDayActivity(_ sharedDayActivity: SharedDayActivity) async throws {
    try await entityHandler.save(sharedDayActivity)
  }

  public func saveSharedDayActivityTask(_ sharedDayActivityTask: SharedDayActivityTask) async throws {
    guard !sharedDayActivityTask.removed else {
      return try await entityHandler.delete(sharedDayActivityTask)
    }
    try await entityHandler.save(sharedDayActivityTask)
  }

  public func removeShareDayActivity(_ sharedDayActivity: SharedDayActivity) async throws {
    try await entityHandler.delete(sharedDayActivity)
  }
}

extension DependencyValues {
  public var dayActivityRepository: DayActivityRepository {
    get { self[DayActivityRepository.self] }
    set { self[DayActivityRepository.self] = newValue }
  }
}

extension DayActivityRepository: DependencyKey {
  public static var liveValue = DayActivityRepository()
}
