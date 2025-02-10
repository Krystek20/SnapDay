import Foundation
import Dependencies
import Models

public struct IconRepository {
  public var saveIcon: @Sendable (Icon) async throws -> Void
  public var fetchIcon: @Sendable (UUID) async throws -> Icon?
  public var fetchAll: @Sendable () async throws -> [Icon]
  public var deleteIcon: @Sendable (UUID) async throws -> Void
  public var deleteIcons: @Sendable ([Icon]) async throws -> Void
}

extension DependencyValues {
  public var iconRepository: IconRepository {
    get { self[IconRepository.self] }
    set { self[IconRepository.self] = newValue }
  }
}

extension IconRepository: DependencyKey {
  public static var liveValue: IconRepository {
    IconRepository(
      saveIcon: { icon in
        try await EntityHandler().save(icon)
      },
      fetchIcon: { identifier in
        try await EntityHandler().fetch(Icon.self, identifier: identifier as CVarArg)
      },
      fetchAll: {
        try await EntityHandler().fetch(Icon.self)
      },
      deleteIcon: { identifier in
        try await EntityHandler().delete(identifier: identifier as CVarArg, Icon.self)
      },
      deleteIcons: { iconsToRemove in
        try await EntityHandler().delete(iconsToRemove)
      }
    )
  }
}
