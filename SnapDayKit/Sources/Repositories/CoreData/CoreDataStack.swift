import Foundation
import CoreData
import Dependencies
import Common
import CloudKit

final class CoreDataStack {

  enum CoreDataStackError: Error {
    case privatePersistentStoreNotExists
    case sharePersistentStoreNotExists
    case canNotFindPersistentStore(id: CKRecord.ID)
  }

  // MARK: - Properties

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
        let recoveryResult = try coreDataBackupService.recoverStore(
          persistentContainer: persistentContainer,
          description: description
        )
        print(
          """
          CoreDataStack recovered store after load failure.
          store: \(description.url?.lastPathComponent ?? "unknown")
          originalError: \(loadPersistentStoresError)
          recovery: \(String(describing: recoveryResult))
          """
        )
      } catch {
        Self.handlePersistentStoreLoadFailure(
          loadPersistentStoresError,
          recoveryError: error,
          description: description
        )
      }
    }

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

    do {
      try coreDataBackupService.scheduleBackups(
        persistentContainer: persistentContainer,
        storeURL: storeUrl,
        description: description
      )
    } catch {
      print("Backup schedule failed: \(error)")
    }

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
  }

  @discardableResult
  func share(managedObjects: [NSManagedObject], to ckShare: CKShare) async throws -> (Set<NSManagedObjectID>, CKShare, CKContainer) {
    try await persistentContainer.share(managedObjects, to: ckShare)
  }

  func fetchShare(matching managedObject: NSManagedObject) throws -> (share: CKShare?, container: CKContainer) {
    let share = try persistentContainer.fetchShares(matching: [managedObject.objectID])[managedObject.objectID]
    let container = CKContainer(identifier: NSPersistentStoreDescription.containerIdentifier)
    return (share, container)
  }

  @discardableResult
  func share(managedObject: NSManagedObject) async throws -> (Set<NSManagedObjectID>, CKShare, CKContainer) {
    try await persistentContainer.share([managedObject], to: nil)
  }

  func fetchParticipants(matching lookupInfos: [CKUserIdentity.LookupInfo]) async throws -> [CKShare.Participant] {
    try await persistentContainer.fetchParticipants(matching: lookupInfos, into: privatePersistentStore)
  }

  @discardableResult
  func persistUpdatedShare(share: CKShare) async throws -> CKShare {
    try await persistentContainer.persistUpdatedShare(share, in: privatePersistentStore)
  }

  @discardableResult
  func purgeObjectsAndRecords(share: CKShare) async throws -> CKRecordZone.ID {
    let persistentStore = try persistentStore(with: share.recordID)
    return try await persistentContainer.purgeObjectsAndRecordsInZone(with: share.recordID.zoneID, in: persistentStore)
  }

  private func persistentStore(with shareRecordID: CKRecord.ID) throws -> NSPersistentStore? {
    if let shares = try? persistentContainer.fetchShares(in: privatePersistentStore) {
      let zoneIDs = shares.map { $0.recordID.zoneID }
      if zoneIDs.contains(shareRecordID.zoneID) {
        return try privatePersistentStore
      }
    }

    if let shares = try? persistentContainer.fetchShares(in: sharedPersistentStore) {
      let zoneIDs = shares.map { $0.recordID.zoneID }
      if zoneIDs.contains(shareRecordID.zoneID) {
        return try sharedPersistentStore
      }
    }

    throw CoreDataStackError.canNotFindPersistentStore(id: shareRecordID)
  }

  func accept(invitation: Invitation) async throws {
    _ = try await persistentContainer.acceptShareInvitations(from: [invitation.cloudKitShareMetadata], into: sharedPersistentStore)
  }

  func recordID(for object: NSManagedObject) -> CKRecord.ID? {
    persistentContainer.recordID(for: object.objectID)
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

private extension CoreDataStack {
  static func handlePersistentStoreLoadFailure(
    _ loadError: NSError,
    recoveryError: Error,
    description: NSPersistentStoreDescription
  ) {
    let message =
      """
      loadPersistentStores failed.
      store: \(description.url?.path ?? "unknown")
      type: \(description.type)
      originalError: \(loadError)
      recoveryError: \(recoveryError)
      """
    assertionFailure(message)
    print(message)
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
