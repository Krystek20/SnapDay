import Foundation
import CoreData

private enum CoreDataStackError: Error {
  case documentDirectoryNotExist
  case securityApplicationDirectoryNotExist
  case backupNotExist
}

final class CoreDataBackupService {

  // MARK: - Properties

  private let fileManager: FileManager

  // MARK: - Initialization

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  // MARK: - Public

  func scheduleBackups(
    persistentContainer: PersistentContainerType,
    storeURL: URL,
    description: NSPersistentStoreDescription
  ) throws {
    Task {
      try await createBackup(
        persistentContainer: persistentContainer,
        description: description
      )
      let contextObjectsDidChangePublished = NotificationCenter
        .default
        .publisher(for: .NSManagedObjectContextObjectsDidChange)
        .debounce(for: .seconds(15), scheduler: DispatchQueue.main)

      for await _ in contextObjectsDidChangePublished.values {
        try await createBackup(persistentContainer: persistentContainer, description: description)
      }
    }
  }

  private func createBackup(
    persistentContainer: PersistentContainerType,
    description: NSPersistentStoreDescription
  ) async throws {
    let temporaryStore = NSPersistentStoreCoordinator(managedObjectModel: persistentContainer.managedObjectModel)
    let newStore = try temporaryStore.addPersistentStore(
      ofType: description.type,
      configurationName: description.configuration,
      at: description.url,
      options: description.options
    )
    _ = try temporaryStore.migratePersistentStore(
      newStore,
      to: fileManager.backupURL,
      options: description.options,
      type: NSPersistentStore.StoreType(rawValue: description.type)
    )
  }

  func loadFromBackup(
    persistentContainer: PersistentContainerType,
    description: NSPersistentStoreDescription
  ) throws {
    guard let storeURL = description.url else { return }
    try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(
      at: storeURL,
      ofType: description.type,
      options: description.options
    )
    if !fileManager.fileExists(atPath: try fileManager.backupURL.path()) {
      throw CoreDataStackError.backupNotExist
    }
    let backupStore = try persistentContainer.persistentStoreCoordinator.addPersistentStore(
      ofType: description.type,
      configurationName: description.configuration,
      at: fileManager.backupURL,
      options: description.options
    )
    _ = try persistentContainer.persistentStoreCoordinator.migratePersistentStore(
      backupStore,
      to: storeURL,
      options: description.options,
      type: NSPersistentStore.StoreType(rawValue: description.type)
    )
  }
}

extension FileManager {
  var backupURL: URL {
    get throws {
      guard let documentDirectory = urls(for: .documentDirectory, in: .userDomainMask).first else {
        throw CoreDataStackError.documentDirectoryNotExist
      }
      let backupDirectoryURL = documentDirectory.appending(path: "SnapDay_Backups")
      if !fileExists(atPath: backupDirectoryURL.path()) {
        try createDirectory(at: backupDirectoryURL, withIntermediateDirectories: true)
      }
      return backupDirectoryURL.appending(path: "SnapDay_1.sqlite")
    }
  }

  var storeURL: URL {
    get throws {
      guard let groupURL = containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroup) else {
        throw CoreDataStackError.securityApplicationDirectoryNotExist
      }
      return groupURL.appendingPathComponent("SnapDay.sqlite")
    }
  }
}
