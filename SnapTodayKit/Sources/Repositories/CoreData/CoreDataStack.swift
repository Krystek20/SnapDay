import Foundation
import CoreData
import os
import Dependencies

final class CoreDataStack {

  // MARK: - Properties

  var backgroundContext: NSManagedObjectContext {
    persistentContainer.newBackgroundContext()
  }
  private let persistentContainer: NSPersistentContainer
  private let context: NSManagedObjectContext

  // MARK: - Private

  private init(
    name: String,
    managedObjectModelType: ManagedObjectModelType.Type = NSManagedObjectModel.self,
    persistentContainerType: PersistentContainerType.Type = NSPersistentContainer.self,
    inMemoryStore: Bool = false
  ) {
    guard let modelURL = Bundle.module.coreDataModelUrl(name: name),
          let managedObjectModel = managedObjectModelType.init(contentsOf: modelURL) else {
      fatalError("managedObjectModel not created for name: \(name)")
    }
    let persistentContainer = persistentContainerType.init(
      name: name,
      managedObjectModel: managedObjectModel
    )
    persistentContainer.loadPersistentStores { _, error in
      guard let error = error as NSError? else { return }
      fatalError("loadPersistentStores failed: \(error.localizedDescription)")
    }

    if inMemoryStore {
      let description = NSPersistentStoreDescription()
      description.type = NSInMemoryStoreType
      description.shouldAddStoreAsynchronously = false
      description.url = URL(filePath: "/dev/null")
      persistentContainer.persistentStoreDescriptions = [description]
    }

    self.persistentContainer = persistentContainer
    self.context = persistentContainer.viewContext
    self.context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
  }
}

// MARK: - Dependecies

extension DependencyValues {
  var coreDataStack: CoreDataStack {
    get { self[CoreDataStack.self] }
    set { self[CoreDataStack.self] = newValue }
  }
}

extension CoreDataStack: DependencyKey {
  static var liveValue: CoreDataStack {
    CoreDataStack(name: "SnapDay")
  }

  static var previewValue: CoreDataStack {
    CoreDataStack(name: "SnapDay", inMemoryStore: true)
  }
}
