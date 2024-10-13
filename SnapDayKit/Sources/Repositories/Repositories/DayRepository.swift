import Foundation
import Dependencies
import Models
import CoreData.NSManagedObjectID

public protocol Repository { }
extension Repository {
  public func object<T: Entity>(objectID: NSManagedObjectID) throws -> T? {
    try EntityHandler().fetch(objectID: objectID)
  }

  public func object<T: Entity>(identifier: UUID) async throws -> T? {
    try await EntityHandler().fetch(T.self) {
      NSPredicate(format: "identifier == %@", identifier.uuidString)
    }
  }
}

public struct FetchConfiguration {
  
  @PredicateBuilder let predicates: () -> [NSPredicate]
  @SortBuilder let sorts: () -> [NSSortDescriptor]

  public init(
    @PredicateBuilder predicates: @escaping () -> [NSPredicate] = { [] },
    @SortBuilder sorts: @escaping () -> [NSSortDescriptor] = { [] }
  ) {
    self.predicates = predicates
    self.sorts = sorts
  }
}

public struct DayRepository: Repository {
  public var loadAllDays: @Sendable () async throws -> [Day]
  public var loadDays: @Sendable (_ configuration: FetchConfiguration) async throws -> [Day]
  public var loadDay: @Sendable (_ date: Date) async throws -> Day?
  public var saveDay: @Sendable (_ day: Day) async throws -> Void
  public var saveDays: @Sendable (_ days: [Day]) async throws -> Void
  public var removeDay: @Sendable (_ day: Day) async throws -> Void
}

extension DependencyValues {
  public var dayRepository: DayRepository {
    get { self[DayRepository.self] }
    set { self[DayRepository.self] = newValue }
  }
}

extension DayRepository: DependencyKey {
  public static var liveValue: DayRepository {
    DayRepository(
      loadAllDays: {
        try await EntityHandler().fetch(Day.self)
      },
      loadDays: { configuration in
        try await EntityHandler().fetch(
          Day.self,
          predicates: configuration.predicates,
          sorts: configuration.sorts
        )
      },
      loadDay: { date in
        try await EntityHandler().fetch(Day.self) {
          NSPredicate(format: "date == %@", date as CVarArg)
        }
      },
      saveDay: { day in
        try await EntityHandler().save(day)
      },
      saveDays: { days in
        try await EntityHandler().save(days)
      },
      removeDay: { day in
        try await EntityHandler().delete(day)
      }
    )
  }

  public static var previewValue: DayRepository {
    DayRepository(
      loadAllDays: { [] },
      loadDays: { _ in [] },
      loadDay: { _ in nil },
      saveDay: { _ in },
      saveDays: { _ in },
      removeDay: { _ in }
    )
  }
}
