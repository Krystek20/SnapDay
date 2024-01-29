import CoreData

public protocol ManagedObjectModelType: NSManagedObjectModel {
  init?(contentsOf url: URL)
}

extension NSManagedObjectModel: ManagedObjectModelType { }
