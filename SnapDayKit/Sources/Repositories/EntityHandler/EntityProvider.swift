import Foundation
import Dependencies
@preconcurrency import CoreData

public struct EntityHandler {

  // MARK: - Dependencies

  @Dependency(\.coreDataStack) private var coreDataStack

  // MARK: - Public

  public func fetch<T: Entity>(
    _ objectType: T.Type,
    @EntityRequestBuilder<NSPredicate> predicates: () -> [NSPredicate] = { [] },
    @EntityRequestBuilder<NSSortDescriptor> sorts: () -> [NSSortDescriptor] = { [] },
    fetchLimit: Int? = nil
  ) async throws -> [T] {
    try await fetch(
      objectType: objectType,
      predicates: predicates(),
      sorts: sorts(),
      fetchLimit: fetchLimit
    )
  }

  public func fetch<T: Entity>(
    objectID: NSManagedObjectID
  ) throws -> T? {
    let context = coreDataStack.backgroundContext
    return try T(object: context.object(with: objectID) as? T.ManagedObject, context: context)
  }

  public func delete(
    objectID: NSManagedObjectID
  ) async throws {
    let context = coreDataStack.backgroundContext
    try await context.perform {
      let object = context.object(with: objectID)
      if object.isFault {
        context.refresh(object, mergeChanges: false)
      }
      context.delete(object)
      do {
        try context.save()
      } catch {
        print("cannot save context: \(error)")
        throw error
      }
    }
  }

  private func fetch<T: Entity>(
    objectType: T.Type,
    predicates: [NSPredicate] = [],
    sorts: [NSSortDescriptor] = [],
    fetchLimit: Int? = nil
  ) async throws -> [T] {
    let request = objectType.fetchRequest
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates + [.deduplicatedDateNilPredicate])
    request.sortDescriptors = sorts
    if let fetchLimit {
      request.fetchLimit = fetchLimit
    }
    let context = coreDataStack.backgroundContext
    return try await context.perform {
      try context.fetch(request)
        .compactMap {
          try T(object: $0, context: context)
        }
    }
  }

  public func fetch<T: Entity>(
    _ objectType: T.Type,
    @EntityRequestBuilder<NSPredicate> predicates: () -> [NSPredicate] = { [] }
  ) async throws -> T? {
    try await fetch(objectType: objectType, predicates: predicates())
  }

  public func fetch<T: Entity>(
    _ objectType: T.Type,
    identifier: CVarArg
  ) async throws -> T? {
    try await fetch(
      objectType: objectType,
      predicates: [NSPredicate(format: "identifier == %@", identifier)]
    )
  }

  private func fetch<T: Entity>(
    objectType: T.Type,
    predicates: [NSPredicate] = []
  ) async throws -> T? {
    let request = objectType.fetchRequest
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates + [.deduplicatedDateNilPredicate])
    request.fetchLimit = 1
    let context = coreDataStack.backgroundContext
    return try await context.perform {
      try T(object: context.fetch(request).first, context: context)
    }
  }

  public func save<T: Entity>(_ entity: T) async throws {
    try await save([entity])
  }

  public func save<T: Entity>(_ entities: [T]) async throws {
    try await transaction { transaction in
      try transaction.save(entities)
    }
  }

  public func delete<T: Entity>(identifier: CVarArg, _ entityType: T.Type) async throws {
    let object = try await fetch(entityType, identifier: identifier)
    guard let object else { return }
    try await delete(object)
  }

  public func delete<T: Entity>(_ entity: T) async throws {
    try await delete([entity])
  }

  public func delete<T: Entity>(_ entities: [T]) async throws {
    try await transaction { transaction in
      try transaction.delete(entities)
    }
  }

  func transaction<Result>(
    _ operation: @escaping @Sendable (EntityTransaction) throws -> Result
  ) async throws -> Result {
    let context = coreDataStack.backgroundContext
    return try await context.perform {
      do {
        let result = try operation(EntityTransaction(context: context))
        if context.hasChanges {
          try context.save()
        }
        return result
      } catch {
        context.rollback()
        throw error
      }
    }
  }
}
