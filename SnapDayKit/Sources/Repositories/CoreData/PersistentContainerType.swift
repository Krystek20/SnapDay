import CoreData
import CloudKit

public protocol PersistentContainerType: AnyObject {
  var viewContext: NSManagedObjectContext { get }
  var persistentStoreCoordinator: NSPersistentStoreCoordinator { get }
  var managedObjectModel: NSManagedObjectModel { get }
  var persistentStoreDescriptions: [NSPersistentStoreDescription] { get set }

  init(name: String, managedObjectModel model: NSManagedObjectModel)
  func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void)
  func newBackgroundContext() -> NSManagedObjectContext
}

public protocol PersistentCloudContainerType: AnyObject {
  func fetchShares(matching objectIDs: [NSManagedObjectID]) throws -> [NSManagedObjectID: CKShare]
  func fetchShares(in persistentStore: NSPersistentStore?) throws -> [CKShare]
  func share(_ managedObjects: [NSManagedObject], to share: CKShare?) async throws -> (Set<NSManagedObjectID>, CKShare, CKContainer)
  func acceptShareInvitations(from metadata: [CKShare.Metadata], into persistentStore: NSPersistentStore) async throws -> [CKShare.Metadata]
  func persistUpdatedShare(_ share: CKShare, in persistentStore: NSPersistentStore) async throws -> CKShare
  func initializeCloudKitSchema(options: NSPersistentCloudKitContainerSchemaInitializationOptions) throws
  func recordID(for managedObjectID: NSManagedObjectID) -> CKRecord.ID?
}

extension NSPersistentContainer: PersistentContainerType { }
extension NSPersistentCloudKitContainer: PersistentCloudContainerType { }

public typealias PersistentContainer = PersistentContainerType & PersistentCloudContainerType
