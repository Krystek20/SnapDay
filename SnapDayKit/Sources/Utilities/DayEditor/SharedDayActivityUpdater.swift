import Foundation
import Dependencies
import Models
import Repositories
import Common

actor SharedDayActivityUpdater {

  enum SharedDayActivitySaverError: Error {
    case objectNotExist
    case userRecordNotExist
    case shareNotExist
  }

  struct Update {
    let sharedDayActivity: SharedDayActivity
    let sharedBy: SharedBy
  }

  // MARK: - Dependecies

  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.iconProvider) private var iconProvider
  @Dependency(\.cloudService) private var cloudService
  @Dependency(\.remoteNotificationRepository) private var remoteNotificationRepository
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date.now) private var now

  // MARK: - Properties

  var updates: [Update] {
    get async throws {
      guard let userRecordName = await cloudService.userRecordName else { return [] }

      let sharedDayActivities = try await dayActivityRepository.sharedDayActivities(
        configuration: ActivitiesFetchConfiguration(
          predicates: [
            NSPredicate(format: "ANY sharedBy.userIdentifier == %@", userRecordName)
          ]
        )
      )

      return sharedDayActivities
        .compactMap { sharedDayActivity in
          guard let sharedBy = sharedDayActivity.sharedBy.first(where: { $0.userId == userRecordName }),
                !sharedBy.objectId.isEmpty else {
            return nil
          }
          return Update(sharedDayActivity: sharedDayActivity, sharedBy: sharedBy)
        }
    }
  }

  private let timeInterval: TimeInterval
  private let attempts: Int
  private let asyncWaiter = AsyncWaiter()

  // MARK: - Initialization

  public init(
    timeInterval: TimeInterval = 30.0,
    attempts: Int = 3
  ) {
    self.timeInterval = timeInterval
    self.attempts = attempts
  }

  // MARK: - Public

  public func addParticipant(_ userRecordName: String, to dayActivity: DayActivity) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivity.id) {
      try await addParticipant(to: dayActivity, participantRecordName: userRecordName)
    }
  }

  public func removeParticipant(_ userRecordName: String, to dayActivity: DayActivity) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivity.id) {
      try await removeParticipant(from: dayActivity, participantRecordName: userRecordName)
    }
  }

  public func stopCollaboration(in dayActivity: DayActivity) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivity.id) {
      guard let userRecordName = await cloudService.userRecordName else { return }
      try await removeParticipant(from: dayActivity, participantRecordName: userRecordName)
    }
  }

  public func acceptInvitation(for dayActivity: DayActivity) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivity.id) {
      guard let userRecordName = await cloudService.userRecordName,
            let invitationId = dayActivity.share?.invitationId,
            var sharedDayActivity = try await dayActivityRepository.sharedDayActivity(identifier: invitationId),
            let index = sharedDayActivity.sharedBy.firstIndex(where: { $0.userId == userRecordName }) else { return }
      let sharedBy = SharedBy(
        identifier: sharedDayActivity.id.uuidString + userRecordName,
        userId: userRecordName,
        objectId: dayActivity.id.uuidString,
        action: .update
      )
      sharedDayActivity.sharedBy[index] = sharedBy

      for (index, sharedTask) in sharedDayActivity.tasks.enumerated() {
        guard let dayActivityTask = dayActivity.dayActivityTasks.first(where: { $0.invitationId == sharedTask.id.uuidString }) else { continue }
        sharedDayActivity.tasks[index].sharedBy.append(
          SharedBy(
            identifier: sharedTask.id.uuidString + userRecordName,
            userId: userRecordName,
            objectId: dayActivityTask.id.uuidString,
            action: .update
          )
        )
      }

      try await save(
        identifier: sharedDayActivity.id,
        option: .update(sharedDayActivity),
        fetchOption: .sharedId
      )

      guard let share = try await cloudService.firstShare(where: dayActivity.id.uuidString) else {
        print("No share")
        return
      }

      await notifyParticipants(
        action: .accept,
        in: share,
        userRecordName: userRecordName,
        participants: sharedDayActivity.sharedBy.map(\.userId),
        activityName: sharedDayActivity.name,
        activityChanges: []
      )
    }
  }

  public func discardInvitation(for dayActivity: DayActivity) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivity.id) {
      guard let userRecordName = await cloudService.userRecordName,
            let invitationId = dayActivity.share?.invitationId,
            var sharedDayActivity = try await dayActivityRepository.sharedDayActivity(identifier: invitationId),
            let index = sharedDayActivity.sharedBy.firstIndex(where: { $0.userId == userRecordName }) else { return }
      sharedDayActivity.sharedBy[index].action = .remove
      try await save(
        identifier: sharedDayActivity.id,
        option: .update(sharedDayActivity),
        fetchOption: .sharedId
      )
    }
  }

  public func updateSharedDayActivity(dayActivity: DayActivity) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivity.id) {
      guard let userRecordName = await cloudService.userRecordName,
            var sharedDayActivity = try await dayActivityRepository.sharedDayActivity(objectId: dayActivity.id.uuidString) else { return }

      await iconProvider.updateIcon(
        with: sharedDayActivity.iconId,
        byIconId: dayActivity.iconId
      )

      let updatedProperties = await sharedDayActivity.update(
        by: dayActivity,
        userRecordName: userRecordName,
        uuid: uuid,
        updateDate: now
      )

      try await save(
        identifier: sharedDayActivity.id,
        option: .update(sharedDayActivity),
        fetchOption: .objectId(dayActivity.id)
      )

      guard let share = try await cloudService.firstShare(where: dayActivity.id.uuidString) else {
        print("No share")
        return
      }

      await notifyParticipants(
        action: .activityUpdated,
        in: share,
        userRecordName: userRecordName,
        participants: sharedDayActivity.sharedBy.map(\.userId),
        activityName: sharedDayActivity.name,
        activityChanges: updatedProperties
      )
    }
  }

  public func updateSharedDayActivityTask(dayActivityTask: DayActivityTask) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivityTask.dayActivityId) {
      guard let userRecordName = await cloudService.userRecordName,
            var sharedDayActivityTask = try await dayActivityRepository.sharedDayActivityTask(objectId: dayActivityTask.id.uuidString) else { return }
      let updatedProperties = await sharedDayActivityTask.update(
        by: dayActivityTask,
        userRecordName: userRecordName,
        updateDate: now
      )
      try await save(
        identifier: sharedDayActivityTask.sharedDayActivityId,
        option: .updateTask(sharedDayActivityTask),
        fetchOption: .objectId(dayActivityTask.id)
      )

      guard let sharedDayActivity = try await dayActivityRepository.sharedDayActivity(objectId: dayActivityTask.dayActivityId.uuidString),
            let share = try await cloudService.firstShare(where: dayActivityTask.dayActivityId.uuidString) else {
        print("No sharedDayActivity or share")
        return
      }

      await notifyParticipants(
        action: .activityUpdated,
        in: share,
        userRecordName: userRecordName,
        participants: sharedDayActivity.sharedBy.map(\.userId),
        activityName: sharedDayActivity.name,
        activityChanges: updatedProperties
      )
    }
  }

  public func removeSharedDayActivity(for dayActivity: DayActivity) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivity.id) {
      guard let sharedDayActivity = try await dayActivityRepository.sharedDayActivity(objectId: dayActivity.id.uuidString) else { return }
      try await save(
        identifier: sharedDayActivity.id,
        option: .remove(sharedDayActivity),
        fetchOption: .objectId(dayActivity.id)
      )
    }
  }

  private func notifyParticipants(
    action: ShareAction,
    in share: Share,
    userRecordName: String,
    participants: [String],
    activityName: String,
    activityChanges: [UpdateProperty]
  ) async {
    guard let userName = share.participants.first(where: \.isCurrentUser)?.name else {
      print("No user name")
      return
    }

    do {
      try await remoteNotificationRepository.notifyParticipants(
        request: NotifyParticipantsRequest(
          userRecord: userRecordName,
          participants: participants,
          action: action,
          userData: [
            .activityName: activityName,
            .userName: userName
          ],
          activityChanges: activityChanges
        )
      )
    } catch {
      print("Update SharedDayActivity - cannot notify participants \(error)")
    }
  }

  // MARK: - Private

  private enum FetchOption {
    case objectId(UUID)
    case sharedId
  }

  private enum SaveOption {
    case update(SharedDayActivity)
    case remove(SharedDayActivity)
    case updateTask(SharedDayActivityTask)
  }

  private func save(
    identifier: UUID,
    option: SaveOption,
    fetchOption: FetchOption
  ) async throws {
    var attempts = attempts
    while attempts > .zero {
      if await isLocked(for: identifier) {
        print("[SharedDayActivitySaver] waiting to unlock... attempts: \(attempts)")
        try await Task.sleep(for: .seconds(timeInterval))
        attempts -= 1
      } else {
        await create(for: identifier)

        switch option {
        case .update(let sharedDayActivity):
          try await saveSharedDayActivity(sharedDayActivity, fetchOption: fetchOption)
        case .remove(let sharedDayActivity):
          try await removeSharedDayActivity(sharedDayActivity)
        case .updateTask(let sharedDayActivityTask):
          try await saveSharedDayActivityTask(sharedDayActivityTask, fetchOption: fetchOption)
        }

        await remove(for: identifier)
        attempts = .zero
      }
    }
  }

  private func saveSharedDayActivity(_ sharedDayActivity: SharedDayActivity, fetchOption: FetchOption) async throws {
    let fetchedSharedDayActivity: SharedDayActivity? = switch fetchOption {
    case .objectId(let identifier):
      try await dayActivityRepository.sharedDayActivity(objectId: identifier.uuidString)
    case .sharedId:
      try await dayActivityRepository.sharedDayActivity(identifier: sharedDayActivity.id.uuidString)
    }

    if var fetchedSharedDayActivity {
      fetchedSharedDayActivity.merge(sharedDayActivity)
      try await dayActivityRepository.saveSharedDayActivity(fetchedSharedDayActivity)
    } else {
      try await dayActivityRepository.saveSharedDayActivity(sharedDayActivity)
    }
  }

  private func removeSharedDayActivity(_ sharedDayActivity: SharedDayActivity) async throws {
    try await dayActivityRepository.removeShareDayActivity(sharedDayActivity)
  }

  private func saveSharedDayActivityTask(_ sharedDayActivityTask: SharedDayActivityTask, fetchOption: FetchOption) async throws {
    let fetchedSharedDayActivityTask: SharedDayActivityTask? = switch fetchOption {
    case .objectId(let identifier):
      try await dayActivityRepository.sharedDayActivityTask(objectId: identifier.uuidString)
    case .sharedId:
      try await dayActivityRepository.sharedDayActivityTask(identifier: sharedDayActivityTask.id.uuidString)
    }

    if var fetchedSharedDayActivityTask {
      fetchedSharedDayActivityTask.merge(sharedDayActivityTask)
      try await dayActivityRepository.saveSharedDayActivityTask(fetchedSharedDayActivityTask)
    } else {
      try await dayActivityRepository.saveSharedDayActivityTask(sharedDayActivityTask)
    }
  }

  // MARK: - Lock

  private func create(for identifier: UUID) async {
    do {
      try await updateTimestamp(Date(), identifier: identifier)
      print("[SharedDayActivitySaver] Lock created")
    } catch {
      print("[SharedDayActivitySaver] Cannot create lock for: \(identifier)")
    }
  }

  private func remove(for identifier: UUID) async {
    do {
      try await updateTimestamp(nil, identifier: identifier)
      print("[SharedDayActivitySaver] Lock removed")
    } catch {
      print("[SharedDayActivitySaver] Cannot remove lock for: \(identifier)")
    }
  }

  private func updateTimestamp(_ date: Date?, identifier: UUID) async throws {
    guard var sharedDayActivity = try await dayActivityRepository.sharedDayActivity(identifier: identifier.uuidString) else {
      throw SharedDayActivitySaverError.objectNotExist
    }
    sharedDayActivity.lockTimestamp = date
    try await dayActivityRepository.saveSharedDayActivity(sharedDayActivity)
  }

  private func isLocked(for identifier: UUID) async -> Bool {
    do {
      guard let timestamp = try await dayActivityRepository.sharedDayActivity(identifier: identifier.uuidString)?.lockTimestamp else {
        return false
      }
      return Date().timeIntervalSince(timestamp) < timeInterval
    } catch {
      print("[SharedDayActivitySaver] Cannot fetch SharedDayActivity for: \(identifier) \(error)")
      return false
    }
  }

  // MARK: - Participants

  private func addParticipant(to dayActivity: DayActivity, participantRecordName: String) async throws {
    guard let userRecordName = await cloudService.userRecordName else {
      throw SharedDayActivitySaverError.userRecordNotExist
    }
    var share = try await getShare(for: dayActivity)

    var sharedDayActivity: SharedDayActivity
    if let existingSharedDayActivity = try await dayActivityRepository.sharedDayActivity(objectId: dayActivity.id.uuidString) {
      sharedDayActivity = existingSharedDayActivity
    } else {
      let icon = await iconProvider.createIcon(from: dayActivity.iconId)
      try await cloudService.saveEntity(icon, to: share)
      sharedDayActivity = SharedDayActivity(
        dayActivity: dayActivity,
        shareableIcon: icon,
        uuid: uuid,
        userRecordName: userRecordName,
        date: now
      )
    }

    if !sharedDayActivity.sharedBy.contains(where: { $0.userId == participantRecordName }) {
      sharedDayActivity.sharedBy.append(
        SharedBy(
          identifier: sharedDayActivity.id.uuidString + participantRecordName,
          userId: participantRecordName,
          action: .update
        )
      )
    }

    if let index = share.sharedDayActivities.firstIndex(where: { $0.id == sharedDayActivity.id }) {
      share.sharedDayActivities[index] = sharedDayActivity
    } else {
      share.sharedDayActivities.append(sharedDayActivity)
    }

    try await cloudService.save(share)

    await notifyParticipants(
      action: .invite,
      in: share,
      userRecordName: userRecordName,
      participants: sharedDayActivity.sharedBy.map(\.userId),
      activityName: sharedDayActivity.name,
      activityChanges: []
    )
  }

  private func getShare(for dayActivity: DayActivity) async throws -> Share {
    let share = if let share = try await cloudService.firstShare(where: dayActivity.id.uuidString) {
      share
    } else if let share = try await cloudService.myShare {
      share
    } else {
      throw SharedDayActivitySaverError.shareNotExist
    }
    return share
  }

  private func removeParticipant(from dayActivity: DayActivity, participantRecordName: String) async throws {
    guard var existingSharedDayActivity = try await dayActivityRepository.sharedDayActivity(objectId: dayActivity.id.uuidString) else { return }

    for (index, sharedBy) in existingSharedDayActivity.sharedBy.enumerated() {
      guard sharedBy.userId == participantRecordName else { continue }
      existingSharedDayActivity.sharedBy[index].action = .remove
    }

    for (taskIndex, task) in existingSharedDayActivity.tasks.enumerated() {
      for (index, sharedBy) in task.sharedBy.enumerated() {
        guard sharedBy.userId == participantRecordName else { continue }
        existingSharedDayActivity.tasks[taskIndex].sharedBy[index].action = .remove
      }
    }

    try await save(
      identifier: existingSharedDayActivity.id,
      option: .update(existingSharedDayActivity),
      fetchOption: .objectId(dayActivity.id)
    )
  }
}
