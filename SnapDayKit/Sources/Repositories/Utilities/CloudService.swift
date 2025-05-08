import Foundation
import CloudKit
import Combine
import Dependencies
import Models

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

  public enum ShareState: Equatable {
    case idle
    case loading
    case loaded
    case failure(String)
  }

  public enum CloudError: Error {
    case serviceNotAvailable
  }

  // MARK: - Dependecies

  @Dependency(\.shareRepository) private var shareRepository
  @Dependency(\.coreDataStack) private var coreDataStack

  public var userRecordName: String? {
    get async {
      do {
        return try await CKContainer.default().userRecordID().recordName
      } catch {
        return nil
      }
    }
  }

  private var cloudState: CloudState {
    get async throws {
      let container = CKContainer.default()
      let accountStatus = try await container.accountStatus()
      return switch accountStatus {
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

  lazy var shareStatePublisher = shareStateSubject.eraseToAnyPublisher()
  private let shareStateSubject = CurrentValueSubject<ShareState, Never>(.idle)

  // MARK: - Public

  public func initializeIfNeeded() async throws {
    guard try await cloudState == .active, shareStateSubject.value == .idle else { return }
    shareStateSubject.send(.loading)

    let subscription = CKQuerySubscription(
      recordType: "UserNotification",
      predicate: NSPredicate(value: true),
      subscriptionID: "collaborationStarted",
      options: .firesOnRecordCreation
    )

    let notificationInfo = CKSubscription.NotificationInfo()
    notificationInfo.shouldSendContentAvailable = true
    subscription.notificationInfo = notificationInfo

    do {
      try await CKContainer.default().publicCloudDatabase.save(subscription)
      print("subscription saved")
    } catch {
      print("Save subscription with error: \(error)")
    }

    do {
      guard let shareEntity = try await fetchShareEntity() else {
        shareStateSubject.send(.failure("Cannot fetch share entity"))
        return
      }
      guard try coreDataStack.fetchShare(matching: shareEntity).share == nil else {
        shareStateSubject.send(.loaded)
        return
      }
      try await coreDataStack.share(managedObject: shareEntity)
      shareStateSubject.send(.loaded)
    } catch {
      shareStateSubject.send(.failure(error.localizedDescription))
    }
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

    guard let shareEntity = try await fetchShareEntity(),
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
    guard let shareEntity = try await fetchShareEntity(),
          let ckShare = try coreDataStack.fetchShare(matching: shareEntity).share else {
      print("shareEntity does not exist")
      return []
    }

    return ckShare.participants.compactMap { ckParticipant in
      guard ckParticipant.role != .owner else { return nil }
      return Participant(ckParticipant, currentUser: ckShare.currentUserParticipant, type: .invited)
    }
  }

  public func removeParticipantFromInvited(_ participant: Participant) async throws {
    guard let shareEntity = try await fetchShareEntity(),
          let ckShare = try coreDataStack.fetchShare(matching: shareEntity).share,
          let ckParticipant = ckShare.participants.first(where: { $0.participantID == participant.id }) else {
      print("shareEntity or participant does not exist")
      return
    }
    ckShare.removeParticipant(ckParticipant)
    try await coreDataStack.persistUpdatedShare(share: ckShare)
  }

  public func invitedBy() async throws -> [Participant] {
    let context = coreDataStack.backgroundContext
    let shares = try await shareRepository.fetchAll()

    let ckShares = try shares.compactMap {
      let shareEntity = try $0.managedObject(context)
      return try coreDataStack.fetchShare(matching: shareEntity).share
    }

    return ckShares.compactMap { ckShare in
      guard ckShare.owner != ckShare.currentUserParticipant else { return nil }
      return Participant(ckShare.owner, currentUser: ckShare.currentUserParticipant, type: .invitee)
    }
  }

  public func stopParticipating(_ participant: Participant) async throws {
    let context = coreDataStack.backgroundContext
    let ckShare = try await shareRepository.fetchAll()
      .first(where: { $0.owner == participant.recordName })
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

  public enum ShareWhere {
    case userRecord(String)
    case shareDayActivity(UUID)
  }

  public func share(where: ShareWhere) async throws -> Share? {
    let context = coreDataStack.backgroundContext
    let allShares = try await shareRepository.fetchAll()

    return try allShares
      .first(where: { share in
        let shareEntity = try share.managedObject(context)
        guard let ckShare = try coreDataStack.fetchShare(matching: shareEntity).share else { return false }

        switch `where` {
        case .userRecord(let userRecord):
          let participants = ckShare.participants.filter {
            $0.userIdentity.userRecordID?.recordName == userRecord || $0 == ckShare.currentUserParticipant
          }
          guard participants.count == 2 else { return false }
          return participants.contains(ckShare.owner)
        case .shareDayActivity(let identifier):
          return share.sharedDayActivities.contains(where: { $0.id == identifier })
        }
      })
  }

  public func firstShare(where objectId: String) async throws -> Share? {
    try await shareRepository.fetchAll()
      .first(where: { share in
        share.sharedDayActivities.contains {
          $0.sharedBy.contains { $0.objectId == objectId }
        }
      })
  }

  public func notify(participantRecordName: String, activityId: String) async throws {
    let database = CKContainer.default().publicCloudDatabase
    let notificationRecord = CKRecord(recordType: "UserNotification")

    notificationRecord["participantRecordName"] = participantRecordName
    notificationRecord["activityId"] = activityId
    notificationRecord["timestamp"] = Date()

    try await database.save(notificationRecord)
  }

  public func handleNotification(_ cloudNotification: CloudNotification) async throws {
    switch cloudNotification {
    case .collaborationStarted(let recordName):
      let database = CKContainer.default().publicCloudDatabase
      let recordId = CKRecord.ID(recordName: recordName)
      do {
        let result = try await database.record(for: recordId)
        print(result)
      } catch {
        print(error)
      }
    }
  }

  public func accept(invitation: Invitation) async throws {
    try await coreDataStack.accept(invitation: invitation)
  }

  // MARK: - Private

  private func addParticipant(lookupInfo: CKUserIdentity.LookupInfo) async throws -> ShareResult? {
    guard let shareEntity = try await fetchShareEntity() else {
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

  private func fetchShareEntity() async throws -> ShareEntity? {
    guard try await cloudState == .active, let userRecordName = await userRecordName else { return nil }
    let share = if let share = try await shareRepository.fetch(userRecordName: userRecordName) {
      share
    } else {
      try await createShare(userRecordName: userRecordName)
    }
    let context = coreDataStack.backgroundContext
    return try share.managedObject(context)
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
    share.participants = ckShare.participants.map { participant in
      Participant(participant, currentUser: ckShare.currentUserParticipant)
    }
  }
}
