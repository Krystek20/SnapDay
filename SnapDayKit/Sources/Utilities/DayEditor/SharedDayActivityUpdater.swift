import Foundation
import Dependencies
import Models
import Repositories

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

  public func addParticipant(_ participant: DayActivityParticipant, to dayActivity: DayActivity) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivity.id) {
      try await addParticipant(to: dayActivity, participant: participant)
    }
  }

  public func removeParticipant(_ participant: DayActivityParticipant, to dayActivity: DayActivity) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivity.id) {
      try await removeParticipant(from: dayActivity, userRecordNameToRemove: participant.userRecordName)
    }
  }

  public func stopCollaboration(in dayActivity: DayActivity) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivity.id) {
      guard let userRecordName = await cloudService.userRecordName else { return }
      try await removeParticipant(from: dayActivity, userRecordNameToRemove: userRecordName)
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
        option: .dayActivity(sharedDayActivity),
        fetchOption: .sharedId
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
        option: .dayActivity(sharedDayActivity),
        fetchOption: .sharedId
      )
    }
  }

  public func updateSharedDayActivity(dayActivity: DayActivity) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivity.id) {
      guard let userRecordName = await cloudService.userRecordName,
            var sharedDayActivity = try await dayActivityRepository.sharedDayActivity(objectId: dayActivity.id.uuidString) else { return }
      await sharedDayActivity.update(
        by: dayActivity,
        userRecordName: userRecordName,
        uuid: uuid,
        updateDate: now
      )
      try await save(
        identifier: sharedDayActivity.id,
        option: .dayActivity(sharedDayActivity),
        fetchOption: .objectId(dayActivity.id)
      )
    }
  }

  public func updateSharedDayActivityTask(dayActivityTask: DayActivityTask) async throws {
    try await asyncWaiter.executeOrWait(for: dayActivityTask.dayActivityId) {
      guard let userRecordName = await cloudService.userRecordName,
            var sharedDayActivityTask = try await dayActivityRepository.sharedDayActivityTask(objectId: dayActivityTask.id.uuidString) else { return }
      await sharedDayActivityTask.update(
        by: dayActivityTask,
        userRecordName: userRecordName,
        updateDate: now
      )
      try await save(
        identifier: sharedDayActivityTask.sharedDayActivityId,
        option: .dayActivityTask(sharedDayActivityTask),
        fetchOption: .objectId(dayActivityTask.id)
      )
    }
  }

  // MARK: - Private

  private enum FetchOption {
    case objectId(UUID)
    case sharedId
  }

  private enum SaveOption {
    case dayActivity(SharedDayActivity)
    case dayActivityTask(SharedDayActivityTask)
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
        case .dayActivity(let sharedDayActivity):
          try await saveSharedDayActivity(sharedDayActivity, fetchOption: fetchOption)
        case .dayActivityTask(let sharedDayActivityTask):
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

  private func addParticipant(to dayActivity: DayActivity, participant: DayActivityParticipant) async throws {
    guard let userRecordName = await cloudService.userRecordName else {
      throw SharedDayActivitySaverError.userRecordNotExist
    }

    let existingSharedDayActivity = try await dayActivityRepository.sharedDayActivity(objectId: dayActivity.id.uuidString)
    var sharedDayActivity: SharedDayActivity

    guard var share = if existingSharedDayActivity != nil {
      try await cloudService.firstShare(where: dayActivity.id.uuidString)
    } else {
      try await cloudService.share(where: participant.userRecordName)
    } else {
      throw SharedDayActivitySaverError.shareNotExist
    }

    sharedDayActivity = existingSharedDayActivity ?? SharedDayActivity(
      dayActivity: dayActivity,
      uuid: uuid,
      userRecordName: userRecordName,
      date: now
    )

    guard !sharedDayActivity.sharedBy.contains(where: { $0.userId == participant.userRecordName }) else { return }
    sharedDayActivity.sharedBy.append(
      SharedBy(
        identifier: sharedDayActivity.id.uuidString + participant.userRecordName,
        userId: participant.userRecordName,
        action: .update
      )
    )

    if let index = share.sharedDayActivities.firstIndex(where: { $0.id == sharedDayActivity.id }) {
      share.sharedDayActivities[index] = sharedDayActivity
    } else {
      share.sharedDayActivities.append(sharedDayActivity)
    }

    if let iconId = sharedDayActivity.iconId,
       let icon = await iconProvider.getIcon(id: iconId) {
      try await cloudService.saveEntity(icon, to: share)
    }

    try await save(
      identifier: sharedDayActivity.id,
      option: .dayActivity(sharedDayActivity),
      fetchOption: .objectId(dayActivity.id)
    )

    try await cloudService.save(share)
    try await cloudService.notify(participantRecordName: participant.userRecordName, activityId: sharedDayActivity.id.uuidString)
  }

  private func removeParticipant(from dayActivity: DayActivity, userRecordNameToRemove: String) async throws {
    guard var existingSharedDayActivity = try await dayActivityRepository.sharedDayActivity(objectId: dayActivity.id.uuidString) else { return }

    for (index, sharedBy) in existingSharedDayActivity.sharedBy.enumerated() {
      guard sharedBy.userId == userRecordNameToRemove else { continue }
      existingSharedDayActivity.sharedBy[index].action = .remove
    }

    for (taskIndex, task) in existingSharedDayActivity.tasks.enumerated() {
      for (index, sharedBy) in task.sharedBy.enumerated() {
        guard sharedBy.userId == userRecordNameToRemove else { continue }
        existingSharedDayActivity.tasks[taskIndex].sharedBy[index].action = .remove
      }
    }

    try await save(
      identifier: existingSharedDayActivity.id,
      option: .dayActivity(existingSharedDayActivity),
      fetchOption: .objectId(dayActivity.id)
    )
  }
}
