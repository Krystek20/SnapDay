import Foundation
import Dependencies
import Models

public struct ActivityLabelRepository {
  public var saveLabel: @Sendable (ActivityLabel) async throws -> Void
  public var deleteLabel: @Sendable (ActivityLabel) async throws -> Void
  public var loadLabels: @Sendable (_ activityId: UUID, _ excludedLabels: [ActivityLabel]) async throws -> [ActivityLabel]
}

extension DependencyValues {
  public var activityLabelRepository: ActivityLabelRepository {
    get { self[ActivityLabelRepository.self] }
    set { self[ActivityLabelRepository.self] = newValue }
  }
}

extension ActivityLabelRepository: DependencyKey {
  public static var liveValue: ActivityLabelRepository {
    ActivityLabelRepository(
      saveLabel: { label in
        try await EntityHandler().save(label)
      },
      deleteLabel: { label in
        try await EntityHandler().delete(label)
      },
      loadLabels: { activityId, excludedTags in
        try await EntityHandler().fetch(
          objectType: ActivityLabel.self,
          predicates: loadLabelsPredicate(activityId: activityId, excludedTags),
          sorts: loadLabelsSorts
        )
      }
    )
  }

  public static var previewValue: ActivityLabelRepository {
    ActivityLabelRepository(
      saveLabel: { _ in },
      deleteLabel: { _ in },
      loadLabels: { _,_ in [] }
    )
  }
}

// MARK: - Helpers

private extension ActivityLabelRepository {
  @PredicateBuilder
  static func loadLabelsPredicate(activityId: UUID, _ excludedLabels: [ActivityLabel]) -> [NSPredicate] {
    let excludedLabelsNames = excludedLabels.map(\.name)
    NSPredicate(format: "activity.identifier == %@ AND NOT (name IN %@)", activityId as CVarArg, excludedLabelsNames)
  }

  @SortBuilder
  static var loadLabelsSorts: [NSSortDescriptor] {
    NSSortDescriptor(key: "name", ascending: true)
  }
}
