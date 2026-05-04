import Foundation
import Dependencies
import Repositories
import Utilities
import AIModule
import Models

public struct ActionsResult: Equatable {
  let results: [UserResponse]
  let decisions: [Decision]
  let decisionResults: [UserResponse]
}

struct ActionParser {

  // MARK: - Dependecies

  @Dependency(\.utcCalendar) private var calendar
  @Dependency(\.uuid) private var uuid
  @Dependency(\.dayUpdater) private var dayUpdater
  @Dependency(\.activityRepository) private var activityRepository
  @Dependency(\.tagRepository) private var tagRepository
  @Dependency(\.activityLabelRepository) private var activityLabelRepository
  @Dependency(\.iconRepository) private var iconRepository

  private var decisionResults: [UserResponse] = []

  // MARK: - Actions

  func parse(
    actions: [ManageActivityAction]
  ) async -> ActionsResult {
    var mutableActions = actions

    var results = [UserResponse]()
    var decisions = [Decision]()

    while mutableActions.isEmpty == false {
      let action = mutableActions.removeFirst()

      var operateResults: [OperateResult] = []
      switch action.payload {
      case .createDayActivity(let payload):
        let (decision, results) = await createDayActivity(action: action, payload: payload, nextActions: &mutableActions)
        if let decision { operateResults.append(.decisition(decision)) }
        operateResults.append(contentsOf: results)
      case .updateDayActivity(let payload):
        let (decision, results) = await updateDayActivity(action: action, payload: payload, nextActions: &mutableActions)
        if let decision { operateResults.append(.decisition(decision)) }
        operateResults.append(contentsOf: results)
      case .deleteDayActivity(let payload):
        operateResults.append(await deleteDayActivity(action: action, payload: payload))
      case .createDayActivityTask(let payload):
        operateResults.append(await createDayActivityTask(action: action, payload: payload))
      case .updateDayActivityTask(let payload):
        operateResults.append(await updateDayActivityTask(action: action, payload: payload))
      case .deleteDayActivityTask(let payload):
        operateResults.append(await deleteDayActivityTask(action: action, payload: payload))
      case .createActivityTemplate(let payload):
        let (decision, results) = await createActivityTemplate(action: action, payload: payload, nextActions: &mutableActions)
        if let decision { operateResults.append(.decisition(decision)) }
        operateResults.append(contentsOf: results)
      case .updateActivityTemplate(let payload):
        operateResults.append(await updateActivityTemplate(action: action, payload: payload))
      case .deleteActivityTemplate(let payload):
        operateResults.append(await deleteActivityTemplate(action: action, payload: payload))
      case .createActivityTemplateTask(let payload):
        operateResults.append(await createActivityTaskTemplate(action: action, payload: payload))
      case .updateActivityTemplateTask(let payload):
        operateResults.append(await updateActivityTaskTemplate(action: action, payload: payload))
      case .deleteActivityTemplateTask(let payload):
        operateResults.append(await deleteActivityTaskTemplate(action: action, payload: payload))
      }

      for operateResult in operateResults {
        switch operateResult {
        case .result(let result):
          results.append(result)
        case .decisition(let decisition):
          decisions.append(decisition)
        }
      }
    }

    return ActionsResult(
      results: results,
      decisions: decisions,
      decisionResults: decisionResults
    )
  }

  // MARK: - Accept / Discard

  mutating func acceptAll(actionsResult: ActionsResult, today: Date) async -> ActionsResult {
    var updatedActionsResult = actionsResult
    for decision in actionsResult.decisions {
      updatedActionsResult = await accept(decision, actionsResult: updatedActionsResult, acceptAll: true, today: today)
    }
    return updatedActionsResult
  }

  mutating func accept(_ decision: Decision, actionsResult: ActionsResult, acceptAll: Bool, today: Date) async -> ActionsResult {
    var updatedActionsResult = actionsResult
    if decision.parameters.result == nil {
      updatedActionsResult = await accept(decision, actionsResult: actionsResult, today: today)
    }
    if acceptAll, case .chain(_, let nextDecisions) = decision {
      for decision in nextDecisions.all where decision.parameters.result == nil {
        updatedActionsResult = await accept(decision, actionsResult: updatedActionsResult, today: today)
      }
    }
    return updatedActionsResult
  }

  private mutating func accept(_ decision: Decision, actionsResult: ActionsResult, today: Date) async -> ActionsResult {
    let result = await accept(decision, today: today)
    print(result)
    setDecisionResults(actionsResult.decisionResults + [result])
    return await parse(actions: actionsResult.decisions.all.map(\.parameters.action))
  }

  private func accept(
    _ decision: Decision,
    today: Date
  ) async -> UserResponse {
    switch decision.parameters.type {
    case .createDayActivity(let dayActivity),
         .updateDayActivity(let dayActivity):
      await accept(decision.parameters.action, objectId: dayActivity.id.uuidString) {
        if var activity = dayActivity.activity {
          let notAdded = dayActivity.labels.filter { dayActivityLabel in
            !activity.labels.contains { $0.name == dayActivity.name }
          }
          if !notAdded.isEmpty {
            activity.labels.append(contentsOf: notAdded)
            try await activityLabelRepository.saveLabels(notAdded)
            try await activityRepository.saveActivity(activity)
          }
        }
        try await tagRepository.saveTags(dayActivity.tags)
        try await dayUpdater.saveDayActivity(dayActivity, syncSharable: true)
      }
    case .deleteDayActivity(let dayActivity):
      await accept(decision.parameters.action, objectId: dayActivity.id.uuidString) {
        try await dayUpdater.removeDayActivity(dayActivity)
      }
    case .createDayActivityTask(_, let dayActivityTask):
      await accept(decision.parameters.action, objectId: dayActivityTask.id.uuidString) {
        if var dayActivity = try await dayUpdater.dayActivity(identifier: dayActivityTask.dayActivityId.uuidString) {
          dayActivity.dayActivityTasks.append(dayActivityTask)
          try await dayUpdater.saveDayActivity(dayActivity, syncSharable: true)
        } else {
          throw NSError(domain: "Day activity not found: \(dayActivityTask.dayActivityId)", code: 7777)
        }
      }
    case .updateDayActivityTask(let dayActivityTask):
      await accept(decision.parameters.action, objectId: dayActivityTask.id.uuidString) {
        try await dayUpdater.saveDayActivityTask(dayActivityTask, syncSharable: true)
      }
    case .deleteDayActivityTask(let dayActivityTask):
      await accept(decision.parameters.action, objectId: dayActivityTask.id.uuidString) {
        try await dayUpdater.removeDayActivityTask(dayActivityTask)
      }
    case.createActivity(let activity),
        .updateActivity(let activity):
      await accept(decision.parameters.action, objectId: activity.id.uuidString) {
        try await tagRepository.saveTags(activity.tags)
        try await activityLabelRepository.saveLabels(activity.labels)
        try await activityRepository.saveActivity(activity)
        try await dayUpdater.updateDaysByUpdatedActivity(activity, from: today)
      }
    case.deleteActivity(let activity):
      await accept(decision.parameters.action, objectId: activity.id.uuidString) {
        try await dayUpdater.updateDaysByRemovedActivity(activity, from: today)
        try await activityRepository.deleteActivity(activity)
      }
    case.createActivityTask(let activity, let activityTask):
      await accept(decision.parameters.action, objectId: activityTask.id.uuidString) {
        if var activity = try await activityRepository.getActivity(identifier: activity.id.uuidString) {
          activity.tasks.append(activityTask)
          try await activityRepository.saveActivity(activity)
          try await dayUpdater.updateDaysByUpdatedActivity(activity, from: today)
        } else {
          throw NSError(domain: "Activity not found: \(activity.id)", code: 7777)
        }
      }
    case .updateActivityTask(let activity, let activityTask):
      await accept(decision.parameters.action, objectId: activityTask.id.uuidString) {
        try await activityRepository.saveActivity(activity)
        try await dayUpdater.updateDaysByUpdatedActivity(activity, from: today)
      }
    case.deleteActivityTask(let activity, let activityTask):
      await accept(decision.parameters.action, objectId: activityTask.id.uuidString) {
        try await dayUpdater.updateDaysByUpdatedActivity(activity, from: today)
        try await activityRepository.deleteActivityTask(activityTask)
        try await activityRepository.saveActivity(activity)
      }
    }
  }

  mutating func discardAll(actionsResult: ActionsResult) async -> ActionsResult {
    var updatedActionsResult = actionsResult
    for decision in actionsResult.decisions {
      updatedActionsResult = await discard(decision, actionsResult: updatedActionsResult)
    }
    return updatedActionsResult
  }

  mutating func discard(_ decision: Decision, actionsResult: ActionsResult) async -> ActionsResult {
    guard decision.parameters.result == nil else { return actionsResult }
    var allDecisions = actionsResult.decisions.all
    var results = actionsResult.decisionResults

    results.append(UserResponse(action: decision.parameters.action, decision: .cancelled))
    allDecisions.removeAll(where: { $0.parameters.action == decision.parameters.action })

    if case .chain(_, let nextDecisions) = decision {
      for decision in nextDecisions.all where decision.parameters.result == nil {
        results.append(UserResponse(action: decision.parameters.action, decision: .cancelled))
        allDecisions.removeAll(where: { $0.parameters.action == decision.parameters.action })
      }
    }

    setDecisionResults(results)
    return await parse(actions: allDecisions.map(\.parameters.action))
  }

  private mutating func discard(decision: Decision, actionsResult: ActionsResult) async -> ActionsResult {
    let result = UserResponse(action: decision.parameters.action, decision: .cancelled)
    print(result)
    setDecisionResults(actionsResult.decisionResults + [result])
    let actionsToParse = actionsResult.decisions.all.filter { $0 != decision }.map(\.parameters.action)
    return await parse(actions: actionsToParse)
  }

  // MARK: - DayActivity

  private func createDayActivity(
    action: ManageActivityAction,
    payload: CreateDayActivity,
    newActivity: Activity? = nil,
    nextActions: inout [ManageActivityAction]
  ) async -> (decision: Decision?, results: [OperateResult]) {
    do {
      let dayActivity: DayActivity
      if let decisionResult = decisionResult(for: action.actionId),
         case .accepted(let identifier) = decisionResult,
         let createdDayActivity = try await dayUpdater.dayActivity(identifier: identifier) {
        dayActivity = createdDayActivity
      } else {
        let activityFromReference = try await getActivityFromReference(payload.reference)
        let activity = newActivity ?? activityFromReference

        if let activity {
          dayActivity = try await DayActivity.create(
            uuid: uuid,
            activity: activity,
            payload: payload,
            tagRepository: tagRepository,
            activityLabelRepository: activityLabelRepository,
            iconRepository: iconRepository,
            calendar: calendar
          )
        } else {
          dayActivity = try await DayActivity(
            uuid: uuid,
            payload: payload,
            tagRepository: tagRepository,
            iconRepository: iconRepository,
            calendar: calendar
          )
        }
      }

      let decisionResult = decisionResult(for: action.actionId)
      let (decisions, operateResults) = await handleConnectedActions(
        action: action,
        dayActivity: dayActivity,
        nextActions: &nextActions
      )
      let decision: Decision = decisions.isEmpty
      ? .leaf(DecisionParameters(action: action, type: .createDayActivity(dayActivity), result: decisionResult))
      : .chain(DecisionParameters(action: action, type: .createDayActivity(dayActivity), result: decisionResult), nextDecisions: decisions)
      return (decision: decision, results: operateResults)
    } catch {
      let result = OperateResult(action, decision: .failed(errorMessage: error.localizedDescription))
      return (decision: nil, results: [result])
    }
  }

  private func updateDayActivity(
    action: ManageActivityAction,
    payload: UpdateDayActivity,
    nextActions: inout [ManageActivityAction]
  ) async -> (decision: Decision?, results: [OperateResult]) {
    do {
      guard case .identifier(let identifier) = payload.reference else {
        throw NSError(domain: "Identifier not provided in reference", code: 8887)
      }
      guard var dayActivity = try await dayUpdater.dayActivity(identifier: identifier) else {
        throw NSError(domain: "[\(action.payload.name)] objectNotFound: \(identifier)", code: 8888)
      }

      let decisionResult = decisionResult(for: action.actionId)
      if decisionResult == nil {
        try await dayActivity.update(
          with: payload,
          uuid: uuid,
          tagRepository: tagRepository,
          activityLabelRepository: activityLabelRepository,
          iconRepository: iconRepository
        )
      }

      let (decisions, operateResults) = await handleConnectedActions(
        action: action,
        dayActivity: dayActivity,
        nextActions: &nextActions
      )
      let decision: Decision = decisions.isEmpty
      ? .leaf(DecisionParameters(action: action, type: .updateDayActivity(dayActivity), result: decisionResult))
      : .chain(DecisionParameters(action: action, type: .updateDayActivity(dayActivity), result: decisionResult), nextDecisions: decisions)
      return (decision: decision, results: operateResults)
    } catch {
      let result = OperateResult(action, decision: .failed(errorMessage: error.localizedDescription))
      return (decision: nil, results: [result])
    }
  }

  private func handleConnectedActions(
    action: ManageActivityAction,
    dayActivity: DayActivity,
    nextActions: inout [ManageActivityAction]
  ) async -> ([Decision], [OperateResult]) {
    var decisions: [Decision] = []
    var operateResults: [OperateResult] = []
    for nextAction in nextActions {
      guard case .createDayActivityTask(let payload) = nextAction.payload,
            isReference(to: dayActivity.id.uuidString, actionId: action.actionId, reference: payload.reference) else { continue }

      if let index = nextActions.firstIndex(of: nextAction) {
        nextActions.remove(at: index)
      }

      do {
        let dayActivityTask = if let decisionResult = decisionResult(for: nextAction.actionId),
           case .accepted(let identifier) = decisionResult,
           let createdDayActivityTask = try await dayUpdater.dayActivityTask(identifier: identifier) {
          createdDayActivityTask
        } else {
          try DayActivityTask(
            uuid: uuid,
            dayActivityId: dayActivity.id,
            payload: payload
          )
        }

        decisions.append(.leaf(
          DecisionParameters(
            action: nextAction,
            type: .createDayActivityTask(dayActivity, dayActivityTask),
            result: decisionResult(for: nextAction.actionId)
          )
        ))
      } catch {
        operateResults.append(
          OperateResult(nextAction, decision: .failed(errorMessage: error.localizedDescription))
        )
      }
    }

    return (decisions, operateResults)
  }

  private func deleteDayActivity(
    action: ManageActivityAction,
    payload: DeleteDayActivity
  ) async -> OperateResult {
    await operateOnObject(for: payload.identifier.uuidString, action: action, fetcher: dayUpdater.dayActivity) { dayActivity in
      OperateResult(leafAction: action, type: .deleteDayActivity(dayActivity), result: decisionResult(for: action.actionId))
    }
  }

  // MARK: - DayActivityTask

  private func createDayActivityTask(
    action: ManageActivityAction,
    payload: CreateDayActivityTask
  ) async -> OperateResult {
    do {
      guard let dayActivityId = getUUIDFrom(reference: payload.reference) else {
        throw NSError(domain: "Day activity id not found: \(payload.reference)", code: 7777)
      }
      let dayActivityTask = try DayActivityTask(
        uuid: uuid,
        dayActivityId: dayActivityId,
        payload: payload,
      )
      guard var dayActivity = try await dayUpdater.dayActivity(identifier: dayActivityTask.dayActivityId.uuidString) else {
        throw NSError(domain: "Day activity not found: \(dayActivityTask.dayActivityId)", code: 7777)
      }
      dayActivity.dayActivityTasks.append(dayActivityTask)
      return OperateResult(leafAction: action, type: .createDayActivityTask(dayActivity, dayActivityTask), result: decisionResult(for: action.actionId))
    } catch {
      return OperateResult(action, decision: .failed(errorMessage: error.localizedDescription))
    }
  }

  private func updateDayActivityTask(
    action: ManageActivityAction,
    payload: UpdateDayActivityTask
  ) async -> OperateResult {
    guard case .identifier(let identifier) = payload.reference else {
      return OperateResult(action, decision: .failed(errorMessage: "Identifier not provided in reference"))
    }
    return await operateOnObject(for: identifier, action: action, fetcher: dayUpdater.dayActivityTask) { dayActivityTask in
      try dayActivityTask.update(with: payload)
      return OperateResult(leafAction: action, type: .updateDayActivityTask(dayActivityTask), result: decisionResult(for: action.actionId))
    }
  }

  private func deleteDayActivityTask(
    action: ManageActivityAction,
    payload: DeleteDayActivityTask
  ) async -> OperateResult {
    await operateOnObject(for: payload.identifier.uuidString, action: action, fetcher: dayUpdater.dayActivityTask) { dayActivityTask in
      OperateResult(leafAction: action, type: .deleteDayActivityTask(dayActivityTask), result: decisionResult(for: action.actionId))
    }
  }

  // MARK: - Activity

  private func createActivityTemplate(
    action: ManageActivityAction,
    payload: CreateActivityTemplate,
    nextActions: inout [ManageActivityAction]
  ) async -> (decision: Decision?, results: [OperateResult]) {
    do {
      var activity = if let decisionResult = decisionResult(for: action.actionId),
         case .accepted(let identifier) = decisionResult,
         let createdActivity = try await activityRepository.getActivity(identifier: identifier) {
        createdActivity
      } else {
        try await Activity(
          uuid: uuid,
          payload: payload,
          tagRepository: tagRepository,
          activityLabelRepository: activityLabelRepository,
          iconRepository: iconRepository
        )
      }

      let (decisions, operateResults) = await handleConnectedActions(
        action: action,
        activity: &activity,
        nextActions: &nextActions
      )
      let decision: Decision = decisions.isEmpty
      ? .leaf(DecisionParameters(action: action, type: .createActivity(activity), result: decisionResult(for: action.actionId)))
      : .chain(DecisionParameters(action: action, type: .createActivity(activity), result: decisionResult(for: action.actionId)), nextDecisions: decisions)
      return (decision: decision, results: operateResults)
    } catch {
      let result = OperateResult(action, decision: .failed(errorMessage: error.localizedDescription))
      return (decision: nil, results: [result])
    }
  }

  private func handleConnectedActions(
    action: ManageActivityAction,
    activity: inout Activity,
    nextActions: inout [ManageActivityAction]
  ) async -> ([Decision], [OperateResult]) {
    var decisions: [Decision] = []
    var operateResults: [OperateResult] = []
    for nextAction in nextActions {
      if case .createActivityTemplateTask(let payload) = nextAction.payload,
         isReference(to: activity.id.uuidString, actionId: action.actionId, reference: payload.reference) {

        if let index = nextActions.firstIndex(of: nextAction) {
          nextActions.remove(at: index)
        }

        do {
          var activityTask: ActivityTask
          if let decisionResult = decisionResult(for: nextAction.actionId),
             case .accepted(let identifier) = decisionResult,
             let createdActivityTask = try await activityRepository.activityTask(identifier) {
            activityTask = createdActivityTask
          } else {
            activityTask = try ActivityTask(uuid: uuid, activityId: activity.id, payload: payload)
          }

          decisions.append(.leaf(
            DecisionParameters(
              action: nextAction,
              type: .createActivityTask(activity, activityTask),
              result: decisionResult(for: nextAction.actionId)
            )
          ))
        } catch {
          operateResults.append(OperateResult(nextAction, decision: .failed(errorMessage: error.localizedDescription)))
        }
      } else if case .createDayActivity(let payload) = nextAction.payload,
                isReference(to: activity.id.uuidString, actionId: action.actionId, reference: payload.reference) {
        if let index = nextActions.firstIndex(of: nextAction) {
          nextActions.remove(at: index)
        }

        let (decision, results) = await createDayActivity(
          action: nextAction,
          payload: payload,
          newActivity: activity,
          nextActions: &nextActions
        )
        if let decision {
          decisions.append(decision)
        }
        operateResults.append(contentsOf: results)
      }
    }
    return (decisions, operateResults)
  }

  private func updateActivityTemplate(
    action: ManageActivityAction,
    payload: UpdateActivityTemplate
  ) async -> OperateResult {
    guard case .identifier(let identifier) = payload.reference else {
      return OperateResult(action, decision: .failed(errorMessage: "Identifier not provided in reference"))
    }
    return await operateOnObject(for: identifier, action: action, fetcher: activityRepository.getActivity) { activity in
      try await activity.update(
        with: payload,
        uuid: uuid,
        tagRepository: tagRepository,
        activityLabelRepository: activityLabelRepository,
        iconRepository: iconRepository
      )
      return OperateResult(leafAction: action, type: .updateActivity(activity), result: decisionResult(for: action.actionId))
    }
  }

  private func deleteActivityTemplate(
    action: ManageActivityAction,
    payload: DeleteActivityTemplate
  ) async -> OperateResult {
    await operateOnObject(for: payload.identifier.uuidString, action: action, fetcher: activityRepository.getActivity) { activity in
      OperateResult(leafAction: action, type: .deleteActivity(activity), result: decisionResult(for: action.actionId))
    }
  }

  // MARK: - ActivityTask

  private func createActivityTaskTemplate(
    action: ManageActivityAction,
    payload: CreateActivityTemplateTask
  ) async -> OperateResult {
    do {
      guard let activityId = getUUIDFrom(reference: payload.reference) else {
        throw NSError(domain: "Activity id not found: \(payload.reference)", code: 7777)
      }
      let activityTask = try ActivityTask(
        uuid: uuid,
        activityId: activityId,
        payload: payload
      )
      guard var activity = try await activityRepository.activity(.id(activityTask.activityId.uuidString)) else {
        throw NSError(domain: "Activity not found: \(activityTask.activityId)", code: 7777)
      }
      activity.tasks.append(activityTask)
      return OperateResult(leafAction: action, type: .createActivityTask(activity, activityTask), result: decisionResult(for: action.actionId))
    } catch {
      return OperateResult(action, decision: .failed(errorMessage: error.localizedDescription))
    }
  }

  private func updateActivityTaskTemplate(
    action: ManageActivityAction,
    payload: UpdateActivityTemplateTask
  ) async -> OperateResult {
    guard case .identifier(let identifier) = payload.reference else {
      return OperateResult(action, decision: .failed(errorMessage: "Identifier not provided in reference"))
    }
    return await operateOnObject(for: identifier, action: action, fetcher: activityRepository.activityTask) { activityTask in
      try activityTask.update(with: payload)
      guard var activity = try await activityRepository.activity(.id(activityTask.activityId.uuidString)) else {
        throw NSError(domain: "Activity not found: \(activityTask.activityId)", code: 7777)
      }
      activity.tasks.removeAll { $0.id == activityTask.id }
      activity.tasks.append(activityTask)
      return OperateResult(leafAction: action, type: .updateActivityTask(activity, activityTask), result: decisionResult(for: action.actionId))
    }
  }

  private func deleteActivityTaskTemplate(
    action: ManageActivityAction,
    payload: DeleteActivityTemplateTask
  ) async -> OperateResult {
    await operateOnObject(for: payload.identifier.uuidString, action: action, fetcher: activityRepository.activityTask) { activityTask in
      guard var activity = try await activityRepository.activity(.id(activityTask.activityId.uuidString)) else {
        throw NSError(domain: "Activity not found: \(activityTask.activityId)", code: 7777)
      }
      activity.tasks.removeAll { $0.id == activityTask.id }
      return OperateResult(leafAction: action, type: .deleteActivityTask(activity, activityTask), result: decisionResult(for: action.actionId))
    }
  }

  // MARK: - Helpers

  private func operateOnObject<T>(
    for objectId: String,
    action: ManageActivityAction,
    fetcher: @escaping (String) async throws -> T?,
    operate: @escaping (inout T) async throws -> OperateResult
  ) async -> OperateResult {
    do {
      guard var object = try await fetcher(objectId) else {
        throw NSError(domain: "[\(action.payload.name)] objectNotFound: \(objectId)", code: 8888)
      }
      return try await operate(&object)
    } catch {
      return OperateResult(action, decision: .failed(errorMessage: error.localizedDescription))
    }
  }

  private func accept(
    _ action: ManageActivityAction,
    objectId: String,
    operate: @escaping () async throws -> Void
  ) async -> UserResponse {
    let decision: UserDecision
    do {
      try await operate()
      decision = .accepted(objectId)
    } catch {
      decision = .failed(errorMessage: "can not perform operation: \(error.localizedDescription)")
    }
    return UserResponse(action: action, decision: decision)
  }

  // MARK: - Helpers

  private func getActivityFromReference(_ reference: Reference) async throws -> Activity? {
    guard let identifier = getIdFrom(reference: reference) else { return nil }
    return try await activityRepository.getActivity(identifier: identifier)
  }

  private func getUUIDFrom(reference: Reference) -> UUID? {
    guard let identifier = getIdFrom(reference: reference) else { return nil }
    return UUID(uuidString: identifier)
  }

  private func isReference(to identifier: String, actionId: String, reference: Reference) -> Bool {
    if let referenceIdentifier = getIdFrom(reference: reference) {
      identifier == referenceIdentifier
    } else if case .actionId(let referenceActionId) = reference {
      actionId == referenceActionId
    } else {
      false
    }
  }

  private func getIdFrom(reference: Reference) -> String? {
    switch reference {
    case .actionId(let actionId):
      switch decisionResult(for: actionId) {
      case .accepted(let identifier):
        identifier
      default:
        nil
      }
    case .identifier(let identifier):
      identifier
    case .none:
      nil
    }
  }

  private mutating func setDecisionResults(_ decisionResults: [UserResponse]) {
    self.decisionResults = decisionResults
  }

  private func decisionResult(for actionId: String) -> UserDecision? {
    decisionResults.first(where: { $0.actionId == actionId })?.decision
  }
}
