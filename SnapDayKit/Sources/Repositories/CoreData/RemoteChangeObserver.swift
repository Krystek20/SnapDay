import CoreData
import Models

final class RemoteChangeObserver {

  // MARK: - Properties

  private let notificationCenter: NotificationCenter
  private let userDefaults: UserDefaults

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
    persistantStoreCoordinator: NSPersistentStoreCoordinator,
    storeURL: URL,
    backgroundContextProvider: () -> NSManagedObjectContext?
  ) async {
    guard let store = persistantStoreCoordinator.persistentStore(for: storeURL) else { return }
    let publisher = notificationCenter.publisher(for: .NSPersistentStoreRemoteChange, object: persistantStoreCoordinator)

    for await notification in publisher.values {
      guard let storeUUID = notification.userInfo?[NSStoreUUIDKey] as? String,
            storeUUID == store.identifier,
            let context = backgroundContextProvider() else { continue }
      performHistory(
        store: store,
        context: context
      )
    }
  }

  private func performHistory(
    store: NSPersistentStore,
    context: NSManagedObjectContext
  ) {
    let token = historyToken(storyUUID: store.identifier)
    let request = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
    request.fetchRequest = NSPersistentHistoryTransaction.fetchRequest
    request.affectedStores = [store]

    let historyResult = try? context.execute(request) as? NSPersistentHistoryResult
    guard let transactions = historyResult?.result as? [NSPersistentHistoryTransaction],
          !transactions.isEmpty else { return }

    let translationsInfo = Transactions(transactions: transactions)
    guard !translationsInfo.isEmpty else { return }

    let userInfo: [UserInfoKey: Any] = [
      UserInfoKey.storeUUID: store.identifier as Any,
      UserInfoKey.transactions: translationsInfo
    ]
    notificationCenter.post(name: .snapDayStoreDidChange, object: userInfo)

    if let newToken = transactions.last?.token {
      updateHistoryToken(storyUUID: store.identifier, newToken: newToken)
    }
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
}
