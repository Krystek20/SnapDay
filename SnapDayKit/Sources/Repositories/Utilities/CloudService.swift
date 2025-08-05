import Foundation
import CloudKit
import Combine
import Dependencies
import Models
import Common

extension DependencyValues {
  public var cloudService: CloudService {
    get { self[CloudService.self] }
    set { self[CloudService.self] = newValue }
  }
}

extension CloudService: DependencyKey {
  public static var liveValue: CloudService {
    CloudService()
  }
}

public actor CloudService {

  public enum CloudState: Equatable {
    case idle
    case active
    case deactive
    case actionNeeded(Action)

    public enum Action: Equatable {
      case login
      case permissions
    }
  }

  public enum CloudError: Error {
    case serviceNotAvailable
  }

  // MARK: - Dependecies

  @Dependency(\.remoteNotificationRepository) private var remoteNotificationRepository
  @Dependency(\.shareRepository) private var shareRepository
  @Dependency(\.coreDataStack) private var coreDataStack

  private let iCloudStore =  NSUbiquitousKeyValueStore.default
  private let isShareEntityGeneratedKey = "isShareEntityGeneratedKey"

  // MARK: - Properties

  private let asyncWaiter = AsyncWaiter()

  public var userRecordName: String? {
    get async {
      do {
        return try await container.userRecordID().recordName
      } catch {
        return nil
      }
    }
  }

  private var cloudState: CloudState {
    get async throws {
      switch try await container.accountStatus() {
      case .available:
          .active
      case .couldNotDetermine:
          .deactive
      case .noAccount:
          .actionNeeded(.login)
      case .restricted:
          .actionNeeded(.permissions)
      case .temporarilyUnavailable:
          .deactive
      @unknown default:
          .deactive
      }
    }
  }

  public var myShare: Share? {
    get async throws {
      let context = coreDataStack.backgroundContext
      return try await allShares()
        .first(where: { share in
          let shareEntity = try share.managedObject(context)
          guard let ckShare = try coreDataStack.fetchShare(matching: shareEntity).share else { return false }
          return ckShare.currentUserParticipant?.role == .owner
        })
    }
  }

  private var shareEntity: ShareEntity? {
    get async throws {
      guard let userRecordName = await userRecordName,
            let share = try await shareRepository.fetch(userRecordName: userRecordName) else {
        return nil
      }
      return try share.managedObject(coreDataStack.backgroundContext)
    }
  }

  private let container = CKContainer(identifier: "iCloud.com.mobilove.snapday")
  private var initializing = false

  // MARK: - Public

  public func initializeIfNeeded() async throws {
    guard !initializing,
          try await cloudState == .active,
          !iCloudStore.bool(forKey: isShareEntityGeneratedKey),
          let userRecordName = await userRecordName else { return }
    initializing = true
    defer { initializing = false }

    try await asyncWaiter.waitUntil(
      deadline: 5.0,
      interval: 1.0,
      action: { [weak self] in
        try await self?.shareEntity != nil
      }
    )

    guard try await shareEntity == nil else {
      iCloudStore.set(true, forKey: isShareEntityGeneratedKey)
      iCloudStore.synchronize()
      return
    }

    let share = try await createShare(userRecordName: userRecordName)
    let shareEntity = try share.managedObject(coreDataStack.backgroundContext)
    try await coreDataStack.share(managedObject: shareEntity)
    iCloudStore.set(true, forKey: isShareEntityGeneratedKey)
    iCloudStore.synchronize()
  }

  public func allShares() async throws -> [Share] {
    var shares = try await shareRepository.fetchAll()
    for (index, var share) in shares.enumerated() {
      try await update(&share)
      shares[index] = share
    }
    return shares
  }

  public func saveEntity(_ entity: any Entity, to share: Share) async throws {
    let context = coreDataStack.backgroundContext
    let object = try entity.managedObject(context)

    guard let shareEntity = try await shareEntity,
          let ckShare = try coreDataStack.fetchShare(matching: shareEntity).share else {
      print("shareEntity does not exist")
      return
    }

    try await coreDataStack.share(managedObjects: [object], to: ckShare)
  }

  public func save(_ share: Share) async throws {
    try await shareRepository.save(share: share)
  }

  public func invited() async throws -> [Participant] {
    guard let shareEntity = try await shareEntity,
          let ckShare = try coreDataStack.fetchShare(matching: shareEntity).share else {
      print("shareEntity does not exist")
      return []
    }

    return ckShare.participants.compactMap { ckParticipant in
      guard ckParticipant.role != .owner else { return nil }
      return Participant(ckParticipant, currentUser: ckShare.currentUserParticipant)
    }
  }

  public func removeParticipantFromInvited(_ participantIds: [String]) async throws {
    guard let shareEntity = try await shareEntity,
          let ckShare = try coreDataStack.fetchShare(matching: shareEntity).share else {
      print("shareEntity does not exist")
      return
    }

    for ckParticipant in ckShare.participants where participantIds.contains(ckParticipant.participantID) {
      ckShare.removeParticipant(ckParticipant)
      try await coreDataStack.persistUpdatedShare(share: ckShare)
    }
  }

  public func stopParticipating(_ recordName: String) async throws {
    let context = coreDataStack.backgroundContext
    let ckShare = try await allShares()
      .first(where: { $0.owner == recordName })
      .flatMap {
        let shareEntity = try $0.managedObject(context)
        return try coreDataStack.fetchShare(matching: shareEntity).share
      }

    guard let ckShare else {
      print("ckShare not not found")
      return
    }

    try await coreDataStack.purgeObjectsAndRecords(share: ckShare)
  }

  public func addParticipant(toEmailAddress: String) async throws -> ShareResult? {
    let lookupInfo = CKUserIdentity.LookupInfo(emailAddress: toEmailAddress)
    return try await addParticipant(lookupInfo: lookupInfo)
  }

  public func addParticipant(toPhoneNumber: String) async throws -> ShareResult? {
    let lookupInfo = CKUserIdentity.LookupInfo(phoneNumber: toPhoneNumber)
    return try await addParticipant(lookupInfo: lookupInfo)
  }

  public func firstShare(where objectId: String) async throws -> Share? {
    try await allShares().first(where: { share in
      share.sharedDayActivities.contains {
        $0.sharedBy.contains { $0.objectId == objectId }
      }
    })
  }

  public func accept(invitation: Invitation) async throws {
    try await coreDataStack.accept(invitation: invitation)

    let ckShare = invitation.cloudKitShareMetadata.share
    let owner = Participant(ckShare.owner, currentUser: ckShare.currentUserParticipant)

    guard let ownerRecordName = owner.recordName else {
      print("Accept - Owner record name not found")
      return
    }

    try await notifyAboutAccepting(ownerRecordName: ownerRecordName)
  }

  // MARK: - Private

  private func addParticipant(lookupInfo: CKUserIdentity.LookupInfo) async throws -> ShareResult? {
    guard let shareEntity = try await shareEntity else {
      print("There is no share entity")
      return nil
    }

    let (share, container) = try coreDataStack.fetchShare(matching: shareEntity)
    guard let share else {
      print("There is no ckShare")
      return nil
    }

    guard let participant = try await coreDataStack.fetchParticipants(matching: [lookupInfo]).first else {
      print("There is no such participant")
      return nil
    }

    participant.permission = .readWrite
    participant.role = .privateUser
    share.addParticipant(participant)
    let updatedShare = try await coreDataStack.persistUpdatedShare(share: share)
    return ShareResult(ckShare: updatedShare, container: container)
  }

  private func createShare(userRecordName: String) async throws -> Share {
    let share = Share(
      owner: userRecordName,
      sharedDayActivities: [],
      isCurrentUserOwner: true,
      participants: []
    )
    try await shareRepository.save(share: share)
    return share
  }

  private func update(_ share: inout Share) async throws {
    let context = coreDataStack.backgroundContext
    let shareEntity = try share.managedObject(context)
    guard let ckShare = try coreDataStack.fetchShare(matching: shareEntity).share else { return }
    share.isCurrentUserOwner = ckShare.currentUserParticipant?.role == .owner
    share.participants = ckShare.participants.map { ckParticipant in
      Participant(ckParticipant, currentUser: ckShare.currentUserParticipant)
    }
  }

  private func currentUserParticipant(inShareOwnedBy: String) async throws -> Participant? {
    let allShares = try await allShares()
    guard let share = allShares.first(where: { $0.owner == inShareOwnedBy }) else {
      return nil
    }
    return share.participants.first(where: \.isCurrentUser)
  }

  private func notifyAboutAccepting(ownerRecordName: String) async throws {
    try await asyncWaiter.waitUntil {
      try await currentUserParticipant(inShareOwnedBy: ownerRecordName)?.acceptanceStatus == .accepted
    }
    let participant = try await currentUserParticipant(inShareOwnedBy: ownerRecordName)

    guard let userRecordName = participant?.recordName,
          let userName = participant?.name else {
      print("Accept - User record name or user name not found")
      return
    }

    do {
      try await remoteNotificationRepository.notifyParticipants(
        request: NotifyParticipantsRequest(
          userRecord: userRecordName,
          participants: [ownerRecordName],
          action: .acceptObserving,
          userData: [.userName: userName]
        )
      )
    } catch {
      print("AcceptObserving - Notification not sent: \(error)")
    }
  }
}

#if DEBUG
import CoreData

extension CloudService {
  public func coreDataEntity(entity: any Entity) throws -> NSManagedObject? {
    let context = coreDataStack.backgroundContext
    return try entity.managedObject(context)
  }

  public func zones() async throws -> [String] {
    let privateDB = container.privateCloudDatabase
    let sharedDB = container.sharedCloudDatabase

    var zoneNames: [String] = []

    let privateZones = try await privateDB.allRecordZones()
    for zone in privateZones {
      zoneNames.append("[P]: " + zone.zoneID.zoneName)
    }

    let sharedZones = try await sharedDB.allRecordZones()
    for zone in sharedZones {
      zoneNames.append("[S]: " + zone.zoneID.zoneName)
    }

    return zoneNames
  }

  public func cleanPrivateZones() async throws {
    let privateDB = container.privateCloudDatabase

    let privateZones = try await privateDB.allRecordZones()
    let defaults = ["com.apple.coredata.cloudkit.zone", "_defaultZone", CKRecordZone.default().zoneID.zoneName]
    NSLog("[CLOUD_SERVICE] - \(defaults)")

    for zone in privateZones where !defaults.contains(zone.zoneID.zoneName) {
      do {
        try await privateDB.deleteRecordZone(withID: zone.zoneID)
        NSLog("[CLOUD_SERVICE] - Zone deleted \(zone.zoneID.zoneName)")
      } catch {
        NSLog("[CLOUD_SERVICE] 🚩 - Zone deleted \(zone.zoneID.zoneName) error \(error)")
      }
    }
  }
}
#endif
