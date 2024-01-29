import Foundation
import Dependencies
import Models

public struct TagRepository {
  public var saveTag: @Sendable (Tag) async throws -> ()
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
        try await EntityHandler().save(tag)
      },
      loadTags: { excludedTags in
        try await EntityHandler().fetch(
          objectType: Tag.self,
          predicates: loadTagsPredicate(excludedTags),
          sorts: loadTagsSorts
        )
      }
    )
  }

  public static var previewValue: TagRepository {
    TagRepository(
      saveTag: { _ in },
      loadTags: { _ in [] }
    )
  }
}

// MARK: - Helpers

private extension TagRepository {
  @PredicateBuilder
  static func loadTagsPredicate(_ excludedTags: [Tag]) -> [NSPredicate] {
    let excludedTagNames = excludedTags.map(\.name)
    if !excludedTags.isEmpty {
      NSPredicate(format: "NOT (name IN %@)", excludedTagNames)
    }
  }

  @SortBuilder
  static var loadTagsSorts: [NSSortDescriptor] {
    NSSortDescriptor(key: "name", ascending: true)
  }
}
