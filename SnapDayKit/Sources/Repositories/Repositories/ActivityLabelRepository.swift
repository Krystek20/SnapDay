import Foundation
import Dependencies
import Models

public struct ActivityLabelRepository {
  public var saveLabel: @Sendable (ActivityLabel) async throws -> Void
  public var saveLabels: @Sendable ([ActivityLabel]) async throws -> Void
  public var deleteLabel: @Sendable (ActivityLabel) async throws -> Void
  public var loadLabels: @Sendable (_ activityId: UUID, _ excludedLabels: [ActivityLabel]) async throws -> [ActivityLabel]
  public var loadLabel: @Sendable (_ activityId: UUID, _ name: String) async throws -> ActivityLabel?
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
        try await EntityHandler().save(label.rgbColor)
        try await EntityHandler().save(label)
      },
      saveLabels: { labels in
        for label in labels {
          try await EntityHandler().save(label.rgbColor)
          try await EntityHandler().save(label)
        }
      },
      deleteLabel: { label in
        try await EntityHandler().delete(label)
      },
      loadLabels: { activityId, excludedLabels in
        let activity = try await EntityHandler().fetch(Activity.self, identifier: activityId as CVarArg)
        guard let activity else { return [] }

        let labels = try await EntityHandler().fetch(
          ActivityLabel.self,
          predicates: {
            NSPredicate(format: "NOT (name IN %@)", excludedLabels.map(\.name))
          },
          sorts: {
            NSSortDescriptor(key: "name", ascending: true)
          }
        )

        return labels.filter(activity.labels.contains)
      },
      loadLabel: { activityId, name in
        guard try await EntityHandler().fetch(Activity.self, identifier: activityId as CVarArg) != nil else { return nil }
        return try await EntityHandler().fetch(ActivityLabel.self) {
          NSPredicate(format: "name == %@", name)
        }
      }
    )
  }

  public static var previewValue: ActivityLabelRepository {
    ActivityLabelRepository(
      saveLabel: { _ in },
      saveLabels: { _ in },
      deleteLabel: { _ in },
      loadLabels: { _,_ in [] },
      loadLabel: { _,_ in nil }
    )
  }
}
