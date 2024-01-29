import Foundation
import Dependencies
import Models

public struct PlanRepository {
  public var loadPlans: @Sendable (Date?, PlanType?) async throws -> [Plan]
  public var savePlan: @Sendable (Plan) async throws -> ()
}

extension DependencyValues {
  public var planRepository: PlanRepository {
    get { self[PlanRepository.self] }
    set { self[PlanRepository.self] = newValue }
  }
}

extension PlanRepository: DependencyKey {
  public static var liveValue: PlanRepository {
    PlanRepository(
      loadPlans: { fromDate, planType in
        try await EntityHandler().fetch(
          objectType: Plan.self,
          predicates: loadPlansPredicates(fromDate, planType)
        )
      },
      savePlan: { plan in
        try await EntityHandler().save(plan)
      }
    )
  }

  public static var previewValue: PlanRepository {
    PlanRepository(
      loadPlans: { fromDate, planType in
        try await withDependencies {
          $0.coreDataStack = .previewValue
        } operation: {
          try await EntityHandler().fetch(
            objectType: Plan.self,
            predicates: loadPlansPredicates(fromDate, planType)
          )
        }
      },
      savePlan: { plan in
        try await withDependencies {
          $0.coreDataStack = .previewValue
        } operation: {
          try await EntityHandler().save(plan)
        }
      }
    )
  }
}

// MARK: - Helpers

private extension PlanRepository {
  @PredicateBuilder
  static func loadPlansPredicates(_ fromDate: Date?, _ planType: PlanType?) -> [NSPredicate] {
    if let fromDate {
      NSPredicate(format: "endDate >= %@", fromDate as CVarArg)
    }
    if let planType {
      NSPredicate(format: "type == %@", planType.rawValue as CVarArg)
    }
  }
}
