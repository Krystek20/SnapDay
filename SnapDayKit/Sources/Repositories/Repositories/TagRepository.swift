import Foundation
import Dependencies
import Models

public struct TagRepository {
  public var saveTag: @Sendable (Tag) async throws -> Void
  public var deleteTag: @Sendable (Tag) async throws -> Void
  public var loadTags: @Sendable (_ excludedTags: [Tag]) async throws -> [Tag]
}

extension DependencyValues {
  public var tagRepository: TagRepository {
    get { self[TagRepository.self] }
    set { self[TagRepository.self] = newValue }
  }
}

extension TagRepository: DependencyKey {
  public static var liveValue: TagRepository {
    TagRepository(
      saveTag: { tag in
        try await EntityHandler().save(tag.rgbColor)
        try await EntityHandler().save(tag)
      },
      deleteTag: { tag in
        try await EntityHandler().delete(tag)
      },
      loadTags: { excludedTags in
        try await EntityHandler().fetch(
          Tag.self,
          predicates: {
            let excludedTagNames = excludedTags.map(\.name)
            if !excludedTags.isEmpty {
              NSPredicate(format: "NOT (name IN %@)", excludedTagNames)
            }
          },
          sorts: {
            NSSortDescriptor(key: "name", ascending: true)
          }
        )
      }
    )
  }

  public static var previewValue: TagRepository {
    TagRepository(
      saveTag: { _ in },
      deleteTag: { _ in },
      loadTags: { _ in [] }
    )
  }
}
