import Foundation
import Dependencies
import CoreData

public protocol Entity {
  associatedtype ManagedObject: NSManagedObject
  static var fetchRequest: NSFetchRequest<ManagedObject> { get }
  init?(object: ManagedObject?) throws
  @discardableResult
  func managedObject(_ context: NSManagedObjectContext) throws -> ManagedObject
}

public extension Entity {
  static var entityName: String? {
    ManagedObject.entity().name
  }
}

public struct EntityHandler {

  // MARK: - Dependencies

  @Dependency(\.coreDataStack) var coreDataStack

  // MARK: - Public

  public func fetch<T: Entity>(
    _ objectType: T.Type,
    @PredicateBuilder predicates: () -> [NSPredicate] = { [] },
    @SortBuilder sorts: () -> [NSSortDescriptor] = { [] }
  ) async throws -> [T] {
    try await fetch(objectType: objectType, predicates: predicates(), sorts: sorts())
  }

  public func fetch<T: Entity>(
    objectID: NSManagedObjectID
  ) throws -> T? {
    let context = coreDataStack.backgroundContext
    return try T(object: context.object(with: objectID) as? T.ManagedObject)
  }

  public func fetch<T: Entity>(
    objectType: T.Type,
    predicates: [NSPredicate] = [],
    sorts: [NSSortDescriptor] = []
  ) async throws -> [T] {
    let request = objectType.fetchRequest
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    request.sortDescriptors = sorts
    let context = coreDataStack.backgroundContext
    return try await context.perform {
      try context.fetch(request)
        .compactMap(objectType.init)
    }
  }

  public func fetch<T: Entity>(
    _ objectType: T.Type,
    @PredicateBuilder predicates: () -> [NSPredicate] = { [] }
  ) async throws -> T? {
    try await fetch(objectType: objectType, predicates: predicates())
  }

  public func fetch<T: Entity>(
    objectType: T.Type,
    predicates: [NSPredicate] = []
  ) async throws -> T? {
    let request = objectType.fetchRequest
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    request.fetchLimit = 1
    let context = coreDataStack.backgroundContext
    return try await context.perform {
      try T(object: context.fetch(request).first)
    }
  }

  public func save<T: Entity>(_ entity: T) async throws {
    let context = coreDataStack.backgroundContext
    return try await context.perform {
      try entity.managedObject(context)
      try context.save()
    }
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

  public func delete<T: Entity>(_ entity: T) async throws {
    let context = coreDataStack.backgroundContext
    return try await context.perform {
      let managedObject = try entity.managedObject(context)
      context.delete(managedObject)
      try context.save()
    }
  }
}
