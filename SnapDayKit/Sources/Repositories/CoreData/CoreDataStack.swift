import Foundation
import CoreData
import Dependencies

final class CoreDataStack {

  // MARK: - Properties

  var backgroundContext: NSManagedObjectContext {
    let context = persistentContainer.newBackgroundContext()
    context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
    context.transactionAuthor = TransactionAuthor.app()
    return context
  }
  private let persistentContainer: PersistentContainerType

  // MARK: - Private

  private init(
    name: String,
    managedObjectModelType: ManagedObjectModelType.Type = NSManagedObjectModel.self,
    persistentContainerType: PersistentContainerType.Type = NSPersistentCloudKitContainer.self,
    coreDataBackupService: CoreDataBackupService = CoreDataBackupService(),
    remoteChangeObserver: RemoteChangeObserver = RemoteChangeObserver(),
    fileManager: FileManager = .default,
    inMemoryStore: Bool = false
  ) {
    guard let modelURL = Bundle.module.coreDataModelUrl(name: name),
          let managedObjectModel = managedObjectModelType.init(contentsOf: modelURL),
          let storeURL = try? fileManager.storeURL else {
      fatalError("managedObjectModel not created for name: \(name)")
    }

    let persistentContainer = persistentContainerType.init(
      name: name,
      managedObjectModel: managedObjectModel
    )

    let description: NSPersistentStoreDescription
    if inMemoryStore {
      description = NSPersistentStoreDescription()
      description.type = NSInMemoryStoreType
      description.shouldAddStoreAsynchronously = false
      description.url = URL(filePath: "/dev/null")
    } else {
      description = NSPersistentStoreDescription(url: storeURL)
      description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.mobilove.snapday")
      description.setOption(true as NSObject, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
      description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    }
    persistentContainer.persistentStoreDescriptions = [description]

    persistentContainer.loadPersistentStores { description, error in
      guard let loadPersistentStoresError = error as NSError? else { return }
      do {
        try coreDataBackupService.loadFromBackup(
          persistentContainer: persistentContainer,
          description: description
        )
      } catch {
        fatalError("loadPersistentStores failed: \(loadPersistentStoresError.localizedDescription) backupError: \(error.localizedDescription)")
      }
    }

    self.persistentContainer = persistentContainer
    self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
    self.persistentContainer.viewContext.transactionAuthor = TransactionAuthor.app()

    do {
        try persistentContainer.viewContext.setQueryGenerationFrom(.current)
    } catch {
        fatalError("Failed to pin viewContext to the current generation:\(error)")
    }

    do {
      try coreDataBackupService.scheduleBackups(
        persistentContainer: persistentContainer,
        storeURL: storeURL,
        description: description
      )
    } catch {
      print("Backup schedule failed: \(error)")
    }

    Task {
      await remoteChangeObserver.startObservingRemoteChanges(
        persistantStoreCoordinator: persistentContainer.persistentStoreCoordinator,
        storeURL: storeURL,
        backgroundContextProvider: { [weak self] in self?.backgroundContext }
      )
    }
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
