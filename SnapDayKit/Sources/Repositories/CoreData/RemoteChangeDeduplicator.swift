@preconcurrency import CoreData

struct RemoteChangeDeduplicator: Sendable {

  func removeDeduplicatedObjects(
    beforeDate: Date,
    store: NSPersistentStore,
    context: NSManagedObjectContext
  ) throws {
    for entity in SupportedDeduplicable.entities {
      try removeDeduplicatedObjects(
        entity: entity,
        beforeDate: beforeDate,
        store: store,
        context: context
      )
    }
  }

  func deduplicate(
    _ inserted: [String?: Set<NSManagedObjectID>],
    context: NSManagedObjectContext,
    persistentContainer: PersistentContainer
  ) throws {
    for managedObjectIds in inserted.values {
      print("[TEST_DEDUPLICATION] - managedObjectIdsCount \(managedObjectIds.count)")
      for managedObjectId in managedObjectIds {
        deduplicate(
          managedObjectId,
          context: context,
          persistentContainer: persistentContainer
        )
      }
    }
    try context.save()
  }

  private func removeDeduplicatedObjects<T: Deduplicable>(
    entity: T.Type,
    beforeDate: Date,
    store: NSPersistentStore,
    context: NSManagedObjectContext
  ) throws {
    let fetchRequest = entity.fetchRequest()
    fetchRequest.affectedStores = [store]
    let format = "(deduplicatedDate != nil) AND (deduplicatedDate < %@)"
    fetchRequest.predicate = NSPredicate(format: format, beforeDate as CVarArg)

    guard let objects = try? context.fetch(fetchRequest) as? [Deduplicable], !objects.isEmpty else { return }
    print("\(#function): Removing deduplicated objects with identifier: \(objects.first?.identifier ?? "nil"), count: \(objects.count).")
    for object in objects {
      context.delete(object)
    }
    try context.save()
  }

  private func deduplicate(
    _ objectId: NSManagedObjectID,
    context: NSManagedObjectContext,
    persistentContainer: PersistentContainer
  ) {
    guard let deduplicable = context.object(with: objectId) as? Deduplicable,
          let identifier = deduplicable.identifier else {
      print("\(#function): Ignore an object that was deleted: \(objectId)")
      return
    }

    guard let name = objectId.entity.name else {
      print("\(#function): No entity name for: \(objectId)")
      return
    }

    let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: name)
    fetchRequest.sortDescriptors = [
      NSSortDescriptor(key: "version", ascending: false),
      NSSortDescriptor(key: "identifier", ascending: true)
    ]
    fetchRequest.predicate = NSCompoundPredicate(
      andPredicateWithSubpredicates: [
        NSPredicate(format: "identifier == %@", identifier as CVarArg),
        NSPredicate(format: "deduplicatedDate == nil")
      ]
    )

    guard var duplicated = try? context.fetch(fetchRequest) as? [Deduplicable], duplicated.count > 1 else {
      return
    }

    let tagZoneID = persistentContainer.recordID(for: deduplicable.objectID)?.zoneID
    duplicated = duplicated.filter {
      persistentContainer.recordID(for: $0.objectID)?.zoneID == tagZoneID
    }

    guard duplicated.count > 1, let indexToReserve = duplicated.indexToReserve else {
      return
    }

    print("\(#function): Deduplicating \(name) with id: \(identifier), count: \(duplicated.count)")

    let objectToReserve = duplicated[indexToReserve]
    duplicated.remove(at: indexToReserve)
    duplicated.deduplicate(to: objectToReserve)
    duplicated.markAsDeduplicated()
  }
}
