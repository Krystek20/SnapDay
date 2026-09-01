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
  func persistUpdatedShare(
    _ share: CKShare,
    in persistentStore: NSPersistentStore,
    completion: (@Sendable (CKShare?, (any Error)?) -> Void)?
  )
  func purgeObjectsAndRecordsInZone(with zoneID: CKRecordZone.ID, in persistentStore: NSPersistentStore?) async throws -> CKRecordZone.ID
  func initializeCloudKitSchema(options: NSPersistentCloudKitContainerSchemaInitializationOptions) throws
  func recordID(for managedObjectID: NSManagedObjectID) -> CKRecord.ID?
  func fetchParticipants(matching lookupInfos: [CKUserIdentity.LookupInfo], into persistentStore: NSPersistentStore) async throws -> [CKShare.Participant]
}

extension NSPersistentContainer: PersistentContainerType { }
extension NSPersistentCloudKitContainer: PersistentCloudContainerType { }

public typealias PersistentContainer = PersistentContainerType & PersistentCloudContainerType
