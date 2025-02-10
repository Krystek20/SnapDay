import Foundation
import CoreData

public protocol Entity {
  associatedtype ManagedObject: NSManagedObject
  static var fetchRequest: NSFetchRequest<ManagedObject> { get }
  init?(object: ManagedObject?, context: NSManagedObjectContext, isShared: (NSManagedObject?) -> Bool) throws
  @discardableResult
  func managedObject(_ context: NSManagedObjectContext) throws -> ManagedObject
}

public extension Entity {
  static var entityName: String? {
    ManagedObject.entity().name
  }
}

extension Entity {
  init?(identifier: String?, context: NSManagedObjectContext, isShared: (NSManagedObject?) -> Bool) throws {
    guard let identifier else { return nil }
    let object = try ManagedObject.object(
      identifier: identifier,
      fetchRequest: Self.fetchRequest,
      context: context
    )
    try self.init(object: object, context: context, isShared: isShared)
  }
}
