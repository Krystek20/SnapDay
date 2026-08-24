import CoreData
import Foundation
import Repositories
import Testing

struct PlanMigrationTests {

  @Test
  func migratesV2StoreToCurrentModelWithoutLosingExistingData() throws {
    let modelDirectory = try #require(try ModelUrlReference.modelUrl(name: "SnapDay"))
    let v2ModelURL = modelDirectory.appending(path: "SnapDay v2.mom")
    let v2Model = try #require(NSManagedObjectModel(contentsOf: v2ModelURL))
    let currentModel = try #require(NSManagedObjectModel(contentsOf: modelDirectory))
    let storeDirectory = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    let storeURL = storeDirectory.appending(path: "SnapDay.sqlite")
    try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: storeDirectory) }

    let oldCoordinator = NSPersistentStoreCoordinator(managedObjectModel: v2Model)
    let oldStore = try oldCoordinator.addPersistentStore(
      type: .sqlite,
      at: storeURL
    )
    let oldContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    oldContext.persistentStoreCoordinator = oldCoordinator
    let tag = NSEntityDescription.insertNewObject(forEntityName: "TagEntity", into: oldContext)
    tag.setValue("migration-test", forKey: "identifier")
    tag.setValue("Migration test", forKey: "name")
    try oldContext.save()
    try oldCoordinator.remove(oldStore)

    let newCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)
    let newStore = try newCoordinator.addPersistentStore(
      type: .sqlite,
      at: storeURL,
      options: [
        NSMigratePersistentStoresAutomaticallyOption: true,
        NSInferMappingModelAutomaticallyOption: true
      ]
    )
    defer { try? newCoordinator.remove(newStore) }
    let newContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    newContext.persistentStoreCoordinator = newCoordinator
    let request = NSFetchRequest<NSManagedObject>(entityName: "TagEntity")
    request.predicate = NSPredicate(format: "identifier == %@", "migration-test")

    #expect(try newContext.count(for: request) == 1)
    #expect(currentModel.entitiesByName["PlanEntity"] != nil)
    #expect(currentModel.entitiesByName["PlanScheduleEntryEntity"] != nil)
    #expect(currentModel.entitiesByName["PlanOccurrenceEntity"] != nil)
  }

  @Test
  func migratesV3OccurrenceWithSkippedDefaultingToFalse() throws {
    let modelDirectory = try #require(try ModelUrlReference.modelUrl(name: "SnapDay"))
    let v3ModelURL = modelDirectory.appending(path: "SnapDay v3.mom")
    let v3Model = try #require(NSManagedObjectModel(contentsOf: v3ModelURL))
    let currentModel = try #require(NSManagedObjectModel(contentsOf: modelDirectory))
    let storeDirectory = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    let storeURL = storeDirectory.appending(path: "SnapDay.sqlite")
    try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: storeDirectory) }

    let planID = UUID()
    let occurrenceID = "migration-occurrence"
    let oldCoordinator = NSPersistentStoreCoordinator(managedObjectModel: v3Model)
    let oldStore = try oldCoordinator.addPersistentStore(type: .sqlite, at: storeURL)
    let oldContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    oldContext.persistentStoreCoordinator = oldCoordinator
    let plan = NSEntityDescription.insertNewObject(forEntityName: "PlanEntity", into: oldContext)
    plan.setValue(planID, forKey: "identifier")
    plan.setValue("Migration plan", forKey: "name")
    let occurrence = NSEntityDescription.insertNewObject(
      forEntityName: "PlanOccurrenceEntity",
      into: oldContext
    )
    occurrence.setValue(occurrenceID, forKey: "identifier")
    occurrence.setValue(planID, forKey: "planIdentifier")
    occurrence.setValue(UUID(), forKey: "activityIdentifier")
    occurrence.setValue(Date(timeIntervalSinceReferenceDate: 800_000_000), forKey: "date")
    occurrence.setValue(plan, forKey: "plan")
    try oldContext.save()
    try oldCoordinator.remove(oldStore)

    let newCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)
    let newStore = try newCoordinator.addPersistentStore(
      type: .sqlite,
      at: storeURL,
      options: [
        NSMigratePersistentStoresAutomaticallyOption: true,
        NSInferMappingModelAutomaticallyOption: true
      ]
    )
    defer { try? newCoordinator.remove(newStore) }
    let newContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    newContext.persistentStoreCoordinator = newCoordinator
    let request = NSFetchRequest<NSManagedObject>(entityName: "PlanOccurrenceEntity")
    request.predicate = NSPredicate(format: "identifier == %@", occurrenceID)
    let migratedOccurrence = try #require(newContext.fetch(request).first)

    #expect(migratedOccurrence.value(forKey: "isSkipped") as? Bool == false)
  }
}
