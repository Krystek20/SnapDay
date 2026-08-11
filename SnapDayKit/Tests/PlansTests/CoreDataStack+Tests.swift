import CoreData
import Foundation
@testable import Repositories

extension CoreDataStack {
  static var plansTestValue: CoreDataStack {
    CoreDataStack(
      name: "SnapDay",
      persistentStoreDescriptions: [
        .plansTestInMemoryStoreDescription,
        .plansTestInMemoryStoreDescription
      ]
    )
  }
}

private extension NSPersistentStoreDescription {
  static var plansTestInMemoryStoreDescription: NSPersistentStoreDescription {
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    description.shouldAddStoreAsynchronously = false
    description.url = URL(filePath: "/dev/null/\(UUID().uuidString)")
    return description
  }
}
