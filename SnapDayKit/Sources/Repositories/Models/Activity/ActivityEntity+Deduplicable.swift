import CoreData.NSManagedObjectID

extension ActivityEntity: Deduplicable {
  func deduplicate(to object: any Deduplicable) { }
}
