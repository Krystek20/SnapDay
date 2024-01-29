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
    fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
    fetchRequest.fetchLimit = 1
    guard let object = try context.fetch(fetchRequest).first else {
      guard let entity = fetchRequest.entity else { throw NSManagedObjectError.entityNotProvided }
      return T(entity: entity, insertInto: context)
    }
    return object
  }
}
