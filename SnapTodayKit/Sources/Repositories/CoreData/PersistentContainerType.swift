import CoreData

public protocol PersistentContainerType: NSPersistentContainer {
  var viewContext: NSManagedObjectContext { get }
  init(name: String, managedObjectModel model: NSManagedObjectModel)
  func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void)
  func newBackgroundContext() -> NSManagedObjectContext
}

extension NSPersistentContainer: PersistentContainerType { }
