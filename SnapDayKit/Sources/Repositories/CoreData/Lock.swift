import Foundation
import CloudKit

public actor Lock {

  // MARK: - Properties

  private let timeInterval: TimeInterval
  private let retryDelay: TimeInterval
  private let attempts: Int
  private let database = CKContainer.default().privateCloudDatabase

  // MARK: - Initialization

  public init(
    timeInterval: TimeInterval = 30.0,
    retryDelay: TimeInterval = 3.0,
    attempts: Int = 5
  ) {
    self.timeInterval = timeInterval
    self.retryDelay = retryDelay
    self.attempts = attempts
  }

  // MARK: - Public

  public func perform(
    for identifier: String,
    action: () async throws -> Void
  ) async throws {
    var attempts = attempts
    while attempts > .zero {
      if await isLocked(for: identifier) {
        print("[LOCK] waiting to unlock... attempts: \(attempts)")
        try await Task.sleep(for: .seconds(retryDelay))
        attempts -= 1
      } else {
        await create(for: identifier)
        try await action()
        await remove(for: identifier)
        attempts = .zero
      }
    }
  }

  // MARK: - Private

  private func create(for identifier: String) async {
    let record = CKRecord(recordType: "Lock")

    record["identifier"] = identifier
    record["lockedByDevice"] = TransactionAuthor.app()
    record["timestamp"] = Date() as CKRecordValue

    do {
      try await database.save(record)
      print("[LOCK] Lock created")
    } catch {
      print("[LOCK] Cannot create lock record: \(error)")
    }
  }

  private func remove(for identifier: String) async {
    let predicate = NSPredicate(format: "identifier == %@", identifier)
    let query = CKQuery(recordType: "Lock", predicate: predicate)

    do {
      let result = try await database.fetch(withQuery: query)
      for record in result.matchResults {
        do {
          try await database.deleteRecord(withID: record.0)
        } catch {
          print("[LOCK] Cannot delete lock record: \(identifier) \(error)")
        }
      }
    } catch {
      print("[LOCK] Cannot fetch locks: \(identifier) \(error)")
    }
  }

  private func isLocked(for identifier: String) async -> Bool {
    let predicate = NSPredicate(format: "identifier == %@", identifier)
    let query = CKQuery(recordType: "Lock", predicate: predicate)

    do {
      let result = try await database.fetch(withQuery: query)
      guard let lock = result.matchResults.first else { return false }
      switch lock.1 {
      case .success(let record):
        guard let timestamp = record["timestamp"] as? Date else { return false }
        return Date().timeIntervalSince(timestamp) < timeInterval
      case .failure(let error):
        print("[LOCK] Cannot match locks: \(identifier) \(error)")
        return false
      }
    } catch {
      print("[LOCK] Cannot fetch locks: \(identifier) \(error)")
      return false
    }
  }
}

private extension CKDatabase {
  func fetch(withQuery query: CKQuery) async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)], queryCursor: CKQueryOperation.Cursor?) {
    try await withCheckedThrowingContinuation { continuation in
      fetch(withQuery: query) { result in
        switch result {
        case .success(let success):
          continuation.resume(returning: success)
        case .failure(let failure):
          continuation.resume(throwing: failure)
        }
      }
    }
  }
}
