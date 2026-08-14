import CoreData
import Dependencies
import Models

public struct PlanCreationRepository {
  public typealias Create = @Sendable (
    _ plan: Plan,
    _ activities: [Activity],
    _ occurrences: [PlanOccurrence]
  ) async throws -> Void

  public var create: Create

  public init(
    create: @escaping Create
  ) {
    self.create = create
  }
}

extension DependencyValues {
  public var planCreationRepository: PlanCreationRepository {
    get { self[PlanCreationRepository.self] }
    set { self[PlanCreationRepository.self] = newValue }
  }
}

extension PlanCreationRepository: DependencyKey {
  public static var liveValue: PlanCreationRepository {
    PlanCreationRepository { plan, activities, occurrences in
      try await PlanCreationPersistence().create(
        plan: plan,
        activities: activities,
        occurrences: occurrences
      )
    }
  }
}

private struct PlanCreationPersistence {
  @Dependency(\.coreDataStack) private var coreDataStack

  func create(
    plan: Plan,
    activities: [Activity],
    occurrences: [PlanOccurrence]
  ) async throws {
    let context = coreDataStack.backgroundContext
    try await context.perform {
      do {
        for activity in activities {
          _ = try activity.managedObject(context)
        }
        _ = try plan.managedObject(context)
        for occurrence in occurrences {
          _ = try occurrence.managedObject(context)
        }
        try context.save()
      } catch {
        context.rollback()
        throw error
      }
    }
  }
}
