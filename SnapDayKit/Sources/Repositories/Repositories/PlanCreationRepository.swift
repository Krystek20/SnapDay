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
      try await EntityHandler().savePlanCreation(
        plan: plan,
        activities: activities,
        occurrences: occurrences
      )
    }
  }
}
