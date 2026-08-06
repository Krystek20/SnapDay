@preconcurrency import CoreData
import Models
import CloudKit

final class RemoteChangeObserver {

  // MARK: - Properties

  private let notificationCenter: NotificationCenter
  private let userDefaults: UserDefaults
  private let deduplicator: RemoteChangeDeduplicator
  private let lock = Lock()
  private let deduplicationIdentifier = "Deduplication"

  // MARK: - Initialization

  init(
    notificationCenter: NotificationCenter = .default,
    userDefaults: UserDefaults = .standard,
    deduplicator: RemoteChangeDeduplicator = RemoteChangeDeduplicator()
  ) {
    self.notificationCenter = notificationCenter
    self.userDefaults = userDefaults
    self.deduplicator = deduplicator
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

      if event.type == .import, event.endDate != nil {
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
    let deduplicator = deduplicator
    try await context.perform {
      try deduplicator.removeDeduplicatedObjects(
        beforeDate: beforeDate,
        store: store,
        context: context
      )
    }
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

    if storeUUID == store.identifier {
      request.affectedStores = [store]
    } else if storeUUID == sharedStore.identifier {
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

    let deduplicator = deduplicator
    try await lock.perform(for: deduplicationIdentifier) {
      try await context.perform {
        try deduplicator.deduplicate(
          inserted,
          context: context,
          persistentContainer: persistentContainer
        )
      }
      print("[TEST_DEDUPLICATION] - Deduplicated")
    }
  }
}
