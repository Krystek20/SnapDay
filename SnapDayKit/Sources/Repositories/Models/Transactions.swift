import Foundation
import CoreData
import Models

public struct Transactions {

  public private(set) var insertedObjectIDs: [String?: Set<NSManagedObjectID>] = [:]
  public private(set) var updatedObjectIDs: [String?: Set<NSManagedObjectID>] = [:]
  public private(set) var deletedObjectIDs: [String?: Set<NSManagedObjectID>] = [:]

  var isEmpty: Bool {
    insertedObjectIDs.isEmpty &&
    updatedObjectIDs.isEmpty &&
    deletedObjectIDs.isEmpty
  }

  // MARK: - Initialization

  init(transactions: [NSPersistentHistoryTransaction]) {
    for transaction in transactions where transaction.changes != nil && transaction.author != TransactionAuthor.app() {
      let changes = transaction.changes ?? []
      for change in changes {
        switch change.changeType {
        case .insert:
          insertedObjectIDs[change.changedObjectID.entity.name, default: []].insert(change.changedObjectID)
        case .update:
          updatedObjectIDs[change.changedObjectID.entity.name, default: []].insert(change.changedObjectID)
        case .delete:
          deletedObjectIDs[change.changedObjectID.entity.name, default: []].insert(change.changedObjectID)
        @unknown default:
          break
        }
      }
    }
  }
}
