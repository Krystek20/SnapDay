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

  func mapIdentifierArray<T: Entity>(for key: String, context: NSManagedObjectContext) throws -> [T] {
    guard let string = value(forKey: key) as? String,
          let data = string.data(using: .utf8) else { return [] }
    return try JSONDecoder().decode([String].self, from: data)
      .compactMap {
        try T(identifier: $0, context: context)
      }
  }
}
