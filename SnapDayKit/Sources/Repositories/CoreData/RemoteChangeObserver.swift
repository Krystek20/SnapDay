import CoreData
import Models
import CloudKit

final class RemoteChangeObserver {

  // MARK: - Properties

  private let notificationCenter: NotificationCenter
  private let userDefaults: UserDefaults
  private let lock = Lock()
  private let deduplicationIdentifier = "Deduplication"

  // MARK: - Initialization

  init(
    notificationCenter: NotificationCenter = .default,
    userDefaults: UserDefaults = .standard
  ) {
    self.notificationCenter = notificationCenter
    self.userDefaults = userDefaults
  }

  // MARK: - Public

  func startObservingRemoteChanges(
    persistentContainer: PersistentContainer,
    store: NSPersistentStore,
    sharedStore: NSPersistentStore,
    backgroundContextProvider: () -> NSManagedObjectContext?
  ) async {
    let remoteChangePublisher = notificationCenter.publisher(for: .NSPersistentStoreRemoteChange, object: persistentContainer.persistentStoreCoordinator)

    for await notification in remoteChangePublisher.values {
      guard let storeUUID = notification.userInfo?[NSStoreUUIDKey] as? String,
            [sharedStore.identifier, store.identifier].contains(storeUUID),
            let context = backgroundContextProvider() else { continue }
      do {
        try await performHistory(
          storeUUID: storeUUID,
          store: store,
          sharedStore: sharedStore,
          context: context,
          persistentContainer: persistentContainer
        )
      } catch {
        print("Can not perform history \(error)")
      }
    }
  }

  func startObservingCloudKitChanges(
    persistentContainer: PersistentContainer,
    store: NSPersistentStore,
    shareStore: NSPersistentStore,
    backgroundContextProvider: () -> NSManagedObjectContext?
  ) async {
    let eventChangedPublisher = notificationCenter.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification, object: persistentContainer)

    for await notification in eventChangedPublisher.values {
      guard let value = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey],
            let event = value as? NSPersistentCloudKitContainer.Event else {
        print("\(#function): Failed to retrieve the container event from notification.userInfo.")
        continue
      }
      guard event.succeeded,
            let context = backgroundContextProvider() else {
        if let error = event.error {
          print("startObservingCloudKitChanges Error: \(error)")
        }
        continue
      }
      do {
        try await removeDeduplicatedObjectsIfNeeded(
          event: event,
          store: store,
          context: context
        )
      } catch {
        print("Can not remove deduplicated objects \(error)")
      }

      if event.type == .import {
        notificationCenter.post(name: .snapDayCloudKitChanged, object: nil)
      }
    }
  }

  private func removeDeduplicatedObjectsIfNeeded(
    event: NSPersistentCloudKitContainer.Event,
    store: NSPersistentStore,
    context: NSManagedObjectContext
  ) async throws {
    let lastExportDateKey = "LastExportDate", lastImportDateKey = "LastImportDate"
    if let endDate = event.endDate {
      switch event.type {
      case .setup:
        return
      case .import:
        UserDefaults.standard.set(endDate, forKey: lastImportDateKey)
      case .export:
        UserDefaults.standard.set(endDate, forKey: lastExportDateKey)
      @unknown default:
        return
      }
    }

    let lastRemoveDeduplicatedObjectsDateKey = "lastRemoveDeduplicatedObjectsDateKey"
    if let theDate = UserDefaults.standard.value(forKey: lastRemoveDeduplicatedObjectsDateKey) as? Date,
       Date.now.timeIntervalSince(theDate) < 60 {
      return
    }

    if let lastExportDate = UserDefaults.standard.value(forKey: lastExportDateKey) as? Date,
       let lastImportDate = UserDefaults.standard.value(forKey: lastImportDateKey) as? Date {
      let earlierDate = min(lastExportDate, lastImportDate)
      try await removeDeduplicatedObjects(
        beforeDate: Date(timeInterval: -60, since: earlierDate),
        store: store,
        context: context
      )
      UserDefaults.standard.set(Date.now, forKey: lastRemoveDeduplicatedObjectsDateKey)
    }
  }

  private func removeDeduplicatedObjects(
    beforeDate: Date,
    store: NSPersistentStore,
    context: NSManagedObjectContext
  ) async throws {
    try await context.perform { [weak self] in
      for entity in SupportedDeduplicable.entities {
        try self?.removeDeduplicatedObjects(
          entity: entity,
          beforeDate: beforeDate,
          store: store,
          context: context
        )
      }
    }
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

  private func performHistory(
    storeUUID: String,
    store: NSPersistentStore,
    sharedStore: NSPersistentStore,
    context: NSManagedObjectContext,
    persistentContainer: PersistentContainer
  ) async throws {
    let token = historyToken(storyUUID: storeUUID)
    let request = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
    request.fetchRequest = NSPersistentHistoryTransaction.fetchRequest
    request.fetchRequest?.predicate = NSPredicate(format: "author != %@", TransactionAuthor.app())

    if store.identifier == store.identifier {
      request.affectedStores = [store]
    } else if store.identifier == sharedStore.identifier {
      request.affectedStores = [sharedStore]
    }

    let historyResult = try? context.execute(request) as? NSPersistentHistoryResult
    guard let transactions = historyResult?.result as? [NSPersistentHistoryTransaction],
          !transactions.isEmpty else { return }

    let translationsInfo = Transactions(transactions: transactions)
    guard !translationsInfo.isEmpty else { return }

    if let newToken = transactions.last?.token {
      updateHistoryToken(storyUUID: storeUUID, newToken: newToken)
    }

    let userInfo: [UserInfoKey: Any] = [
      UserInfoKey.storeUUID: store.identifier as Any,
      UserInfoKey.transactions: translationsInfo
    ]

    notificationCenter.post(name: .snapDayStoreDidChange, object: userInfo)

    try await deduplicate(
      translationsInfo.insertedObjectIDs,
      context: context,
      persistentContainer: persistentContainer
    )
  }

  private func historyToken(storyUUID: String) -> NSPersistentHistoryToken? {
    guard let data = userDefaults.data(forKey: tokenKey(storyUUID: storyUUID)) else { return nil }
    return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
  }

  private func updateHistoryToken(storyUUID: String, newToken: NSPersistentHistoryToken) {
    let data = try? NSKeyedArchiver.archivedData(withRootObject: newToken, requiringSecureCoding: true)
    userDefaults.setValue(data, forKey: tokenKey(storyUUID: storyUUID))
  }

  private func tokenKey(storyUUID: String) -> String {
    "historyToken:" + storyUUID
  }

  private func deduplicate(
    _ inserted: [String?: Set<NSManagedObjectID>],
    context: NSManagedObjectContext,
    persistentContainer: PersistentContainer
  ) async throws {
    print("[TEST_DEDUPLICATION] - START: \(inserted.count)")

    try await lock.perform(for: deduplicationIdentifier) {
      try await context.perform { [weak self] in
        for managedObjectIds in inserted.values {
          print("[TEST_DEDUPLICATION] - managedObjectIdsCount \(managedObjectIds.count)")
          for managedObjectId in managedObjectIds {
            self?.deduplicate(managedObjectId, context: context, persistentContainer: persistentContainer)
          }
        }
        try context.save()
      }
      print("[TEST_DEDUPLICATION] - Deduplicated")
    }
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
