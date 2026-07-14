import CoreData
import Foundation
@testable import Repositories

extension CoreDataStack {
  static var testValue: CoreDataStack {
    CoreDataStack(
      name: "SnapDay",
      persistentStoreDescriptions: [
        .testInMemoryStoreDescription,
        .testInMemoryStoreDescription
      ]
    )
  }
}

private extension NSPersistentStoreDescription {
  static var testInMemoryStoreDescription: NSPersistentStoreDescription {
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    description.shouldAddStoreAsynchronously = false
    description.url = URL(filePath: "/dev/null/\(UUID().uuidString)")
    return description
  }
}
