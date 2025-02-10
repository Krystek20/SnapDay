import Foundation
import CoreData
import Dependencies
import Common
import CloudKit

public final class CoreDataStack {

  enum CoreDataStackError: Error {
    case privatePersistentStoreNotExists
    case sharePersistentStoreNotExists
  }

  // MARK: - Properties

  func isShared(object: NSManagedObject?) -> Bool {
    guard let object,
          let shareSet = try? persistentContainer.fetchShares(matching: [object.objectID]) else { return false }
    return !shareSet.isEmpty
  }

  var backgroundContext: NSManagedObjectContext {
    let context = persistentContainer.newBackgroundContext()
    context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
    context.transactionAuthor = TransactionAuthor.app()
    return context
  }
  private let persistentContainer: PersistentContainer

  private let storeUrl: URL
  private var privatePersistentStore: NSPersistentStore {
    get throws {
      guard let store = persistentContainer.persistentStoreCoordinator.persistentStore(for: storeUrl) else {
        throw CoreDataStackError.privatePersistentStoreNotExists
      }
      return store
    }
  }
  private let sharedStoreUrl: URL
  private var sharedPersistentStore: NSPersistentStore {
    get throws {
      guard let store = persistentContainer.persistentStoreCoordinator.persistentStore(for: sharedStoreUrl) else {
        throw CoreDataStackError.sharePersistentStoreNotExists
      }
      return store
    }
  }

  // MARK: - Private

  private init(
    name: String,
    managedObjectModelType: ManagedObjectModelType.Type = NSManagedObjectModel.self,
    persistentContainerType: PersistentContainer.Type = NSPersistentCloudKitContainer.self,
    coreDataBackupService: CoreDataBackupService = CoreDataBackupService(),
    remoteChangeObserver: RemoteChangeObserver = RemoteChangeObserver(),
    fileManager: FileManager = .default,
    inMemoryStore: Bool = false
  ) {
    guard let modelURL = Bundle.module.coreDataModelUrl(name: name),
          let managedObjectModel = managedObjectModelType.init(contentsOf: modelURL),
          let storeUrl = try? fileManager.storeUrl else {
      fatalError("managedObjectModel not created for name: \(name)")
    }
    let sharedStoreUrl = storeUrl.deletingLastPathComponent().appendingPathComponent("shared.sqlite")
    self.storeUrl = storeUrl
    self.sharedStoreUrl = sharedStoreUrl

    let persistentContainer = persistentContainerType.init(
      name: name,
      managedObjectModel: managedObjectModel
    )

    let description: NSPersistentStoreDescription
    let sharedDescription: NSPersistentStoreDescription
    if inMemoryStore {
      description = .inMemoryPersistentStoreDescription
      sharedDescription = .inMemoryPersistentStoreDescription
    } else {
      (description, sharedDescription) = NSPersistentStoreDescription.persistentStoreDescriptions(
        storeUrl: storeUrl,
        sharedStoreUrl: sharedStoreUrl
      )
    }
    persistentContainer.persistentStoreDescriptions = [description, sharedDescription]

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

//    self.persistentContainer = persistentContainer
//    DispatchQueue.main.async {
//      do {
//        print("\(#function): initializeCloudKitSchema")
//        try persistentContainer.initializeCloudKitSchema(options: [])
//      } catch {
//        print("\(#function): initializeCloudKitSchema: \(error)")
//      }
//    }

//    // TU
      self.persistentContainer = persistentContainer
      self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
      self.persistentContainer.viewContext.transactionAuthor = TransactionAuthor.app()
      self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true

      do {
          try persistentContainer.viewContext.setQueryGenerationFrom(.current)
      } catch {
          fatalError("Failed to pin viewContext to the current generation:\(error)")
      }

      guard Bundle.main.isMainApp else { return }

//      do {
//        try coreDataBackupService.scheduleBackups(
//          persistentContainer: persistentContainer,
//          storeURL: storeUrl,
//          description: description
//        )
//      } catch {
//        print("Backup schedule failed: \(error)")
//      }

      Task {
        await remoteChangeObserver.startObservingRemoteChanges(
          persistentContainer: persistentContainer,
          store: try privatePersistentStore,
          sharedStore: try sharedPersistentStore,
          backgroundContextProvider: { [weak self] in self?.backgroundContext }
        )
      }

      Task {
        await remoteChangeObserver.startObservingCloudKitChanges(
          persistentContainer: persistentContainer,
          store: try privatePersistentStore,
          shareStore: try sharedPersistentStore,
          backgroundContextProvider: { [weak self] in self?.backgroundContext }
        )
      }
//     //  TU
  }

  func fetchShares(in persistentStores: [NSPersistentStore]) throws -> [CKShare] {
    var results = [CKShare]()
    for persistentStore in persistentStores {
      do {
        let shares = try persistentContainer.fetchShares(in: persistentStore)
        results += shares
      } catch let error {
        print("Failed to fetch shares in \(persistentStore).")
        throw error
      }
    }
    return results
  }

  func share(managedObject: NSManagedObject, dependeciesObjects: [NSManagedObject]) async throws -> Share {
    let startTime = Date()
    var ckShare: CKShare
    var ckContainer: CKContainer
    if let share = try persistentContainer.fetchShares(matching: [managedObject.objectID])[managedObject.objectID] {
      ckShare = share
      ckContainer = CKContainer(identifier: NSPersistentStoreDescription.containerIdentifier)
    } else {
      let (_, share, container) = try await persistentContainer.share([managedObject], to: nil)
      ckShare = share
      ckContainer = container
    }

    let executionTime1 = Date().timeIntervalSince(startTime)
    print("executionTime1: \(executionTime1) seconds")

    if !dependeciesObjects.isEmpty {
      let (_, share, container) = try await persistentContainer.share(dependeciesObjects, to: ckShare)
      ckShare = share
      ckContainer = container
    }

    let executionTime2 = Date().timeIntervalSince(startTime)
    print("executionTime2: \(executionTime2) seconds")

    let share = try await persistentContainer.persistUpdatedShare(ckShare, in: privatePersistentStore)

    let executionTime3 = Date().timeIntervalSince(startTime)
    print("executionTime3: \(executionTime3) seconds")

    return Share(
      ckShare: share,
      container: ckContainer
    )
  }

  func accept(invitation: Invitation) async throws {
    let startTime = Date()
    let meta = try await persistentContainer.acceptShareInvitations(from: [invitation.cloudKitShareMetadata], into: sharedPersistentStore)
    let endTime = Date()
    let executionTime = endTime.timeIntervalSince(startTime)
    print("executionTime: \(executionTime) seconds")
    print(meta)
//    guard invitation.cloudKitShareMetadata.containerIdentifier == NSPersistentStoreDescription.containerIdentifier else {
//      print("Shared container identifier \(invitation.cloudKitShareMetadata.containerIdentifier) did not match known identifier.")
//      return
//    }
//
//    let container = CKContainer(identifier: NSPersistentStoreDescription.containerIdentifier)
//    let operation = CKAcceptSharesOperation(shareMetadatas: [invitation.cloudKitShareMetadata])
//
//    debugPrint("Accepting CloudKit Share with metadata: \(invitation.cloudKitShareMetadata)")
//
//    operation.perShareResultBlock = { metadata, result in
//      let rootRecordID = metadata.rootRecord?.recordID
//
//      switch result {
//      case .failure(let error):
//        debugPrint("Error accepting share with root record ID: \(rootRecordID), \(error)")
//
//      case .success:
//        debugPrint("Accepted CloudKit share for root record ID: \(rootRecordID)")
//      }
//    }
//
//    operation.acceptSharesResultBlock = { result in
//      if case .failure(let error) = result {
//        debugPrint("Error accepting CloudKit Share: \(error)")
//      }
//    }
//
//    operation.qualityOfService = .utility
//    container.add(operation)
//
//    guard let sharedPersistentStore else {
//      print("sharedPersistentStore not loaded.")
//      return
//    }

//    let meta = try await persistentContainer.acceptShareInvitations(from: [invitation.cloudKitShareMetadata], into: sharedPersistentStore)
//    print(meta)
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
  public static var liveValue: CoreDataStack {
    CoreDataStack(name: "SnapDay")
  }

  public static var previewValue: CoreDataStack {
    CoreDataStack(name: "SnapDay", inMemoryStore: true)
  }
}

private extension NSPersistentStoreDescription {

  static let containerIdentifier = "iCloud.com.mobilove.snapday"

  static let inMemoryPersistentStoreDescription: NSPersistentStoreDescription = {
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    description.shouldAddStoreAsynchronously = false
    description.url = URL(filePath: "/dev/null")
    return description
  }()

  static func persistentStoreDescriptions(
    storeUrl: URL,
    sharedStoreUrl: URL
  ) -> (
    privateDescription: NSPersistentStoreDescription,
    sharedDescription: NSPersistentStoreDescription
  ) {
    let privateDescription = NSPersistentStoreDescription(url: storeUrl)
    privateDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
    privateDescription.setOption(true as NSObject, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    privateDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    privateDescription.shouldMigrateStoreAutomatically = true
    privateDescription.shouldInferMappingModelAutomatically = false

    guard let copiedDescription = privateDescription.copy() as? NSPersistentStoreDescription else {
      fatalError("copy description failed")
    }

    let sharedDescription = copiedDescription
    sharedDescription.url = sharedStoreUrl

    let sharedStoreOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
    sharedStoreOptions.databaseScope = .shared
    sharedDescription.cloudKitContainerOptions = sharedStoreOptions

    return (privateDescription: privateDescription, sharedDescription: sharedDescription)
  }
}
