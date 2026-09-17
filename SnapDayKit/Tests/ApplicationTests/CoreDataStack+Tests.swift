import CoreData
import Foundation
@testable import Repositories

extension CoreDataStack {
  static var applicationTestValue: CoreDataStack {
    CoreDataStack(
      name: "SnapDay",
      persistentStoreDescriptions: [
        .applicationTestInMemoryStoreDescription,
        .applicationTestInMemoryStoreDescription
      ]
    )
  }
}

private extension NSPersistentStoreDescription {
  static var applicationTestInMemoryStoreDescription: NSPersistentStoreDescription {
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    description.shouldAddStoreAsynchronously = false
    description.url = URL(filePath: "/dev/null/\(UUID().uuidString)")
    return description
  }
}
