import CoreData.NSManagedObjectID

extension ActivityTaskEntity: Deduplicable {
  func deduplicate(to object: any Deduplicable) { }
}
