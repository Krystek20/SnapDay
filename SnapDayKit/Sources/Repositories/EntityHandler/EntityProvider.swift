import Foundation
import Dependencies
import CoreData

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
    return try T(object: context.object(with: objectID) as? T.ManagedObject, context: context, isShared: { object in
      coreDataStack.isShared(object: object)
    })
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
          try objectType.init(object: $0, context: context, isShared: { object in
            coreDataStack.isShared(object: object)
          })
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
      try T(object: context.fetch(request).first, context: context, isShared: { object in
        coreDataStack.isShared(object: object)
      })
    }
  }

  public func save<T: Entity>(_ entity: T) async throws {
    try await save([entity])
  }

  public func save<T: Entity>(_ entities: [T]) async throws {
    let context = coreDataStack.backgroundContext
    return try await context.perform {
      try entities.forEach {
        try $0.managedObject(context)
        try context.save()
      }
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
    let context = coreDataStack.backgroundContext
    return try await context.perform {
      try entities.forEach {
        let managedObject = try $0.managedObject(context)
        context.delete(managedObject)
      }
      try context.save()
    }
  }

  public func share(
    _ entity: any Entity,
    dependecies: [any Entity],
    title: String,
    thumbnailImageData: Data?
  ) async throws -> Share {
    let context = coreDataStack.backgroundContext
    let managedObject = try entity.managedObject(context)
    let dependeciesObjects = try dependecies.map {
      try $0.managedObject(context)
    }
    do {
      let share = try await coreDataStack.share(managedObject: managedObject, dependeciesObjects: dependeciesObjects)
      await context.perform {
        share.fill(with: title, thumbnailImageData: thumbnailImageData)
      }
      return share
    } catch {
      print("Error: \(error)")
      throw error
    }
  }

  public func accept(invitation: Invitation) async throws {
    try await coreDataStack.accept(invitation: invitation)
  }
}
