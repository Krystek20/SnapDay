import CoreData

struct EntityTransaction {
  private let context: NSManagedObjectContext

  init(context: NSManagedObjectContext) {
    self.context = context
  }

  func fetch<T: Entity>(
    _ objectType: T.Type,
    @EntityRequestBuilder<NSPredicate> predicates: () -> [NSPredicate] = { [] },
    @EntityRequestBuilder<NSSortDescriptor> sorts: () -> [NSSortDescriptor] = { [] },
    fetchLimit: Int? = nil
  ) throws -> [T] {
    let request = objectType.fetchRequest
    request.predicate = NSCompoundPredicate(
      andPredicateWithSubpredicates: predicates() + [.deduplicatedDateNilPredicate]
    )
    request.sortDescriptors = sorts()
    if let fetchLimit {
      request.fetchLimit = fetchLimit
    }
    return try context.fetch(request).compactMap {
      try T(object: $0, context: context)
    }
  }

  func fetch<T: Entity>(
    _ objectType: T.Type,
    identifier: CVarArg
  ) throws -> T? {
    try fetch(
      objectType,
      predicates: { NSPredicate(format: "identifier == %@", identifier) },
      fetchLimit: 1
    ).first
  }

  func save<T: Entity>(_ entity: T) throws {
    try save([entity])
  }

  func save<T: Entity>(_ entities: [T]) throws {
    for entity in entities {
      _ = try entity.managedObject(context)
    }
  }

  func delete<T: Entity>(_ entity: T) throws {
    try delete([entity])
  }

  func delete<T: Entity>(_ entities: [T]) throws {
    for entity in entities {
      context.delete(try entity.managedObject(context))
    }
  }
}
