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
  func create(
    plan: Plan,
    activities: [Activity],
    occurrences: [PlanOccurrence]
  ) async throws {
    try await EntityHandler().transaction { transaction in
      try transaction.save(activities)
      try transaction.save(plan)
      try transaction.save(occurrences)
    }
  }
}
