import Foundation
import CoreData

private enum CoreDataStackError: Error {
  case documentDirectoryNotExist
  case securityApplicationDirectoryNotExist
  case backupNotExist
}

enum CoreDataRecoveryResult: Equatable {
  case restoredFromBackup
  case recreatedEmptyStore
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
  ) {
    Task {
      do {
        try await createBackup(
          persistentContainer: persistentContainer,
          description: description
        )
      } catch {
        print("Initial Core Data backup failed: \(error)")
      }

      let contextObjectsDidChangePublished = NotificationCenter
        .default
        .publisher(for: .NSManagedObjectContextObjectsDidChange)
        .debounce(for: .seconds(15), scheduler: DispatchQueue.main)

      for await _ in contextObjectsDidChangePublished.values {
        do {
          try await createBackup(persistentContainer: persistentContainer, description: description)
        } catch {
          print("Core Data backup failed: \(error)")
        }
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
      to: fileManager.prepareURLForBackup(),
      options: description.options,
      type: NSPersistentStore.StoreType(rawValue: description.type)
    )
  }

  func recoverStore(
    persistentContainer: PersistentContainerType,
    description: NSPersistentStoreDescription
  ) throws -> CoreDataRecoveryResult {
    do {
      try restoreStoreFromBackup(
        persistentContainer: persistentContainer,
        description: description
      )
      return .restoredFromBackup
    } catch {
      try recreateStore(
        persistentContainer: persistentContainer,
        description: description
      )
      return .recreatedEmptyStore
    }
  }

  private func restoreStoreFromBackup(
    persistentContainer: PersistentContainerType,
    description: NSPersistentStoreDescription
  ) throws {
    guard let storeURL = description.url else { return }
    let backupURL = try fileManager.getURLToRestore()
    if !fileManager.fileExists(atPath: backupURL.path()) {
      throw CoreDataStackError.backupNotExist
    }
    try destroyStore(
      persistentContainer: persistentContainer,
      description: description
    )
    let backupStore = try persistentContainer.persistentStoreCoordinator.addPersistentStore(
      ofType: description.type,
      configurationName: description.configuration,
      at: backupURL,
      options: description.options
    )
    _ = try persistentContainer.persistentStoreCoordinator.migratePersistentStore(
      backupStore,
      to: storeURL,
      options: description.options,
      type: NSPersistentStore.StoreType(rawValue: description.type)
    )
  }

  private func recreateStore(
    persistentContainer: PersistentContainerType,
    description: NSPersistentStoreDescription
  ) throws {
    try destroyStore(
      persistentContainer: persistentContainer,
      description: description
    )
    _ = try persistentContainer.persistentStoreCoordinator.addPersistentStore(
      ofType: description.type,
      configurationName: description.configuration,
      at: description.url,
      options: description.options
    )
  }

  private func destroyStore(
    persistentContainer: PersistentContainerType,
    description: NSPersistentStoreDescription
  ) throws {
    guard let storeURL = description.url else { return }
    try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(
      at: storeURL,
      ofType: description.type,
      options: description.options
    )
  }
}

extension FileManager {
  var storeUrl: URL {
    get throws {
      guard let groupURL = containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroup) else {
        throw CoreDataStackError.securityApplicationDirectoryNotExist
      }
      return groupURL.appendingPathComponent("SnapDay.sqlite")
    }
  }

  fileprivate func prepareURLForBackup() throws -> URL {
    guard let documentDirectory = urls(for: .documentDirectory, in: .userDomainMask).first else {
      throw CoreDataStackError.documentDirectoryNotExist
    }
    let backupDirectoryURL = documentDirectory.appending(path: "SnapDay_Backups")
    let firstSqlite = backupDirectoryURL.appending(path: "SnapDay_1.sqlite")
    let secondSqlite = backupDirectoryURL.appending(path: "SnapDay_2.sqlite")

    if !fileExists(atPath: backupDirectoryURL.path()) {
      try createDirectory(at: backupDirectoryURL, withIntermediateDirectories: true)
    }

    switch (fileExists(atPath: firstSqlite.path()), fileExists(atPath: secondSqlite.path())) {
    case (false, false):
      return firstSqlite
    case (true, false):
      return secondSqlite
    case (false, true):
      return firstSqlite
    case (true, true):
      let attributes1 = try attributesOfItem(atPath: firstSqlite.path())
      let attributes2 = try attributesOfItem(atPath: secondSqlite.path())
      let urlToDeleteAndReturn: URL
      guard let creationDate1 = attributes1[.creationDate] as? Date,
            let creationDate2 = attributes2[.creationDate] as? Date else {
        try removeItem(at: firstSqlite)
        return firstSqlite
      }
      urlToDeleteAndReturn = creationDate1 < creationDate2
      ? firstSqlite
      : secondSqlite
      try removeItem(at: urlToDeleteAndReturn)
      return urlToDeleteAndReturn
    }
  }

  fileprivate func getURLToRestore() throws -> URL {
    guard let documentDirectory = urls(for: .documentDirectory, in: .userDomainMask).first else {
      throw CoreDataStackError.documentDirectoryNotExist
    }
    let backupDirectoryURL = documentDirectory.appending(path: "SnapDay_Backups")
    let firstSqlite = backupDirectoryURL.appending(path: "SnapDay_1.sqlite")
    let secondSqlite = backupDirectoryURL.appending(path: "SnapDay_2.sqlite")

    switch (fileExists(atPath: firstSqlite.path()), fileExists(atPath: secondSqlite.path())) {
    case (true, true):
      let attributes1 = try attributesOfItem(atPath: firstSqlite.path())
      let attributes2 = try attributesOfItem(atPath: secondSqlite.path())
      guard let creationDate1 = attributes1[.creationDate] as? Date,
            let creationDate2 = attributes2[.creationDate] as? Date else {
        fallthrough
      }
      return creationDate1 > creationDate2
      ? firstSqlite
      : secondSqlite
    case (true, false):
      return firstSqlite
    case (false, true):
      return secondSqlite
    case (false, false):
      throw CoreDataStackError.backupNotExist
    }
  }
}
