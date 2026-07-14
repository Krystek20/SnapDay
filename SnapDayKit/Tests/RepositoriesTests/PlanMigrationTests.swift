import CoreData
import Foundation
import Repositories
import Testing

struct PlanMigrationTests {

  @Test
  func migratesV2StoreToV3WithoutLosingExistingData() throws {
    let modelDirectory = try #require(try ModelUrlReference.modelUrl(name: "SnapDay"))
    let v2ModelURL = modelDirectory.appending(path: "SnapDay v2.mom")
    let v2Model = try #require(NSManagedObjectModel(contentsOf: v2ModelURL))
    let v3Model = try #require(NSManagedObjectModel(contentsOf: modelDirectory))
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

    let newCoordinator = NSPersistentStoreCoordinator(managedObjectModel: v3Model)
    _ = try newCoordinator.addPersistentStore(
      type: .sqlite,
      at: storeURL,
      options: [
        NSMigratePersistentStoresAutomaticallyOption: true,
        NSInferMappingModelAutomaticallyOption: true
      ]
    )
    let newContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    newContext.persistentStoreCoordinator = newCoordinator
    let request = NSFetchRequest<NSManagedObject>(entityName: "TagEntity")
    request.predicate = NSPredicate(format: "identifier == %@", "migration-test")

    #expect(try newContext.count(for: request) == 1)
    #expect(v3Model.entitiesByName["PlanEntity"] != nil)
    #expect(v3Model.entitiesByName["PlanScheduleEntryEntity"] != nil)
    #expect(v3Model.entitiesByName["PlanOccurrenceEntity"] != nil)
  }
}
