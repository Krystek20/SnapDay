import CoreData.NSManagedObject

enum NSManagedObjectError: Error {
  case entityNotProvided
}

extension NSManagedObject {
  static func object<T: NSManagedObject>(
    identifier: String,
    fetchRequest: NSFetchRequest<T>,
    context: NSManagedObjectContext
  ) throws -> T {
    fetchRequest.predicate = NSCompoundPredicate(
      andPredicateWithSubpredicates: [
        NSPredicate(format: "identifier == %@", identifier),
        NSPredicate.deduplicatedDateNilPredicate
      ]
    )
    fetchRequest.fetchLimit = 1
    guard let object = try context.fetch(fetchRequest).first else {
      guard let entity = fetchRequest.entity else { throw NSManagedObjectError.entityNotProvided }
      return T(entity: entity, insertInto: context)
    }
    return object
  }

  func mapArray<T: Entity>(for key: String, context: NSManagedObjectContext, isShared: (NSManagedObject?) -> Bool) throws -> [T] {
    guard let data = value(forKey: key) as? Data else { return [] }
    return try JSONDecoder().decode([String].self, from: data)
      .compactMap {
        try T(identifier: $0, context: context, isShared: isShared)
      }
  }
}
