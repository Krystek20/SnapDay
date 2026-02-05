import Foundation
import Dependencies
import Repositories
import Utilities
import AIModule
import Models

public struct ActionsResult: Equatable {
  let results: [ManageActivityActionResultRequest]
  let decisions: [Decision]
  let decisionResults: [ManageActivityActionResultRequest]
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

  private var decisionResults: [ManageActivityActionResultRequest] = []

  // MARK: - Initialization

  init() { }

  // MARK: - Parsing

  func parse(
    actions: [ManageActivityAction]
  ) async -> ActionsResult {
    var mutableActions = actions

    var results = [ManageActivityActionResultRequest]()
    var decisions = [Decision]()

    while mutableActions.isEmpty == false {
      let action = mutableActions.removeFirst()

      var operateResults: [OperateResult] = []
      switch action.action {
      case .getDayActivities:
        operateResults.append(await getDayActivities(action: action))
      case .getDayActivity:
        operateResults.append(await getDayActivity(action: action))
      case .createDayActivity:
        let (decision, results) = await createDayActivity(action: action, nextActions: &mutableActions)
        if let decision { operateResults.append(.decisition(decision)) }
        operateResults.append(contentsOf: results)
      case .updateDayActivity:
        operateResults.append(await updateDayActivity(action: action))
      case .deleteDayActivity:
        operateResults.append(await deleteDayActivity(action: action))
      case .createDayActivityTask:
        operateResults.append(await createDayActivityTask(action: action))
      case .getActivityTemplates:
        operateResults.append(await getActivityTemplates(action: action))
      case .getActivityTemplate:
        operateResults.append(await getActivityTemplate(action: action))
      case .updateDayActivityTask:
        operateResults.append(await updateDayActivityTask(action: action))
      case .deleteDayActivityTask:
        operateResults.append(await deleteDayActivityTask(action: action))
      case .createActivityTemplate:
        let (decision, results) = await createActivityTemplate(action: action, nextActions: &mutableActions)
        if let decision { operateResults.append(.decisition(decision)) }
        operateResults.append(contentsOf: results)
      case .updateActivityTemplate:
        operateResults.append(await updateActivityTemplate(action: action))
      case .deleteActivityTemplate:
        operateResults.append(await deleteActivityTemplate(action: action))
      case .createActivityTemplateTask:
        operateResults.append(await createActivityTaskTemplate(action: action))
      case .updateActivityTemplateTask:
        operateResults.append(await updateActivityTaskTemplate(action: action))
      case .deleteActivityTemplateTask:
        operateResults.append(await deleteActivityTaskTemplate(action: action))
      case .getTags:
        operateResults.append(await getTags(action: action))
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
  ) async -> ManageActivityActionResultRequest {
    switch decision.parameters.decisionType {
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

    results.append(ManageActivityActionResultRequest(action: decision.parameters.action, decisionResult: .userCancelled))
    allDecisions.removeAll(where: { $0.parameters.action == decision.parameters.action })

    if case .chain(_, let nextDecisions) = decision {
      for decision in nextDecisions.all where decision.parameters.result == nil {
        results.append(ManageActivityActionResultRequest(action: decision.parameters.action, decisionResult: .userCancelled))
        allDecisions.removeAll(where: { $0.parameters.action == decision.parameters.action })
      }
    }

    setDecisionResults(results)
    return await parse(actions: allDecisions.map(\.parameters.action))
  }

  private mutating func discard(decision: Decision, actionsResult: ActionsResult) async -> ActionsResult {
    let result = ManageActivityActionResultRequest(action: decision.parameters.action, decisionResult: .userCancelled)
    print(result)
    setDecisionResults(actionsResult.decisionResults + [result])
    let actionsToParse = actionsResult.decisions.all.filter { $0 != decision }.map(\.parameters.action)
    return await parse(actions: actionsToParse)
  }

  // MARK: - DayActivity

  private func getDayActivities(action: ManageActivityAction) async -> OperateResult {
    do {
      guard let iso8601Date = ISO8601DateFormatter.date(from: action.fields?["date"]?.stringValue) else {
        throw NSError(domain: "fieldsNotFound: date", code: 9999)
      }
      let date = calendar.dayFormat(iso8601Date)
      let configuration = ActivitiesFetchConfiguration(range: date...date)
      let dayActivities = try await dayUpdater.dayActivities(configuration: configuration)
      return OperateResult(action, fetchResult: .fetched(dayActivities.map(DayActivityRequest.init)))
    } catch {
      return OperateResult(action, fetchResult: .failed(errorMessage: error.localizedDescription))
    }
  }

  private func getDayActivity(action: ManageActivityAction) async -> OperateResult {
    await operateOnObject(for: action, fetcher: dayUpdater.dayActivity) { dayActivity in
      OperateResult(action, fetchResult: .fetched(DayActivityRequest(dayActivity: dayActivity)))
    }
  }

  private func createDayActivity(
    action: ManageActivityAction,
    newActivity: Activity? = nil,
    nextActions: inout [ManageActivityAction]
  ) async -> (decision: Decision?, results: [OperateResult]) {
    do {
      let dayActivity: DayActivity
      if let decisionResult = decisionResult(for: action.actionId),
         decisionResult == .accepted,
         let identifier = action.fields?["identifier"]?.stringValue,
         let createdDayActivity = try await dayUpdater.dayActivity(identifier: identifier) {
        dayActivity = createdDayActivity
      } else {
        var activity: Activity?
        if let newActivity {
          activity = newActivity
        } else if let identifier = action.fields?["templateIdentifier"]?.stringValue {
          activity = try await activityRepository.getActivity(identifier: identifier)
        }

        if let activity {
          dayActivity = try await DayActivity.create(
            uuid: uuid,
            activity: activity,
            action: action,
            tagRepository: tagRepository,
            activityLabelRepository: activityLabelRepository,
            iconRepository: iconRepository,
            calendar: calendar
          )
        } else {
          dayActivity = try await DayActivity(
            uuid: uuid,
            action: action,
            activityRepository: activityRepository,
            tagRepository: tagRepository,
            activityLabelRepository: activityLabelRepository,
            iconRepository: iconRepository,
            calendar: calendar
          )
        }
      }

      let decisionResult = decisionResult(for: action.actionId)
      let (decisions, operateResults) = await handleConnectedActions(for: dayActivity, nextActions: &nextActions)
      let decision: Decision = decisions.isEmpty
      ? .leaf(DecisionParameters(action, type: .createDayActivity(dayActivity), result: decisionResult))
      : .chain(DecisionParameters(action, type: .createDayActivity(dayActivity), result: decisionResult), nextDecisions: decisions)
      return (decision: decision, results: operateResults)
    } catch {
      let result = OperateResult(action, fetchResult: .failed(errorMessage: error.localizedDescription))
      return (decision: nil, results: [result])
    }
  }

  private func handleConnectedActions(
    for dayActivity: DayActivity,
    nextActions: inout [ManageActivityAction]
  ) async -> ([Decision], [OperateResult]) {
    var decisions: [Decision] = []
    var operateResults: [OperateResult] = []
    for nextAction in nextActions {
      guard case .createDayActivityTask = nextAction.action,
            dayActivity.id == nextAction.fields?["dayActivityId"]?.uuidValue else { continue }

      if let index = nextActions.firstIndex(of: nextAction) {
        nextActions.remove(at: index)
      }

      do {
        let dayActivityTask: DayActivityTask
        if let decisionResult = decisionResult(for: nextAction.actionId),
           decisionResult == .accepted,
           let identifier = nextAction.fields?["identifier"]?.stringValue,
           let createdDayActivityTask = try await dayUpdater.dayActivityTask(identifier: identifier) {
          dayActivityTask = createdDayActivityTask
        } else {
          dayActivityTask = try DayActivityTask(uuid: uuid, action: nextAction)
        }

        decisions.append(.leaf(DecisionParameters(nextAction, type: .createDayActivityTask(dayActivity, dayActivityTask), result: decisionResult(for: nextAction.actionId))))
      } catch {
        operateResults.append(
          OperateResult(nextAction, fetchResult: .failed(errorMessage: error.localizedDescription))
        )
      }
    }

    return (decisions, operateResults)
  }

  private func updateDayActivity(action: ManageActivityAction) async -> OperateResult {
    await operateOnObject(for: action, fetcher: dayUpdater.dayActivity) { dayActivity in
      try await dayActivity.update(
        with: action,
        uuid: uuid,
        tagRepository: tagRepository,
        activityLabelRepository: activityLabelRepository,
        iconRepository: iconRepository
      )
      return OperateResult(leafAction: action, type: .updateDayActivity(dayActivity), result: decisionResult(for: action.actionId))
    }
  }

  private func deleteDayActivity(action: ManageActivityAction) async -> OperateResult {
    await operateOnObject(for: action, fetcher: dayUpdater.dayActivity) { dayActivity in
      OperateResult(leafAction: action, type: .deleteDayActivity(dayActivity), result: decisionResult(for: action.actionId))
    }
  }

  // MARK: - DayActivityTask

  private func createDayActivityTask(action: ManageActivityAction) async -> OperateResult {
    do {
      let dayActivityTask = try DayActivityTask(uuid: uuid, action: action)
      guard var dayActivity = try await dayUpdater.dayActivity(identifier: dayActivityTask.dayActivityId.uuidString) else {
        throw NSError(domain: "Day activity not found: \(dayActivityTask.dayActivityId)", code: 7777)
      }
      dayActivity.dayActivityTasks.append(dayActivityTask)
      return OperateResult(leafAction: action, type: .createDayActivityTask(dayActivity, dayActivityTask), result: decisionResult(for: action.actionId))
    } catch {
      return OperateResult(action, fetchResult: .failed(errorMessage: error.localizedDescription))
    }
  }

  private func updateDayActivityTask(action: ManageActivityAction) async -> OperateResult {
    await operateOnObject(for: action, fetcher: dayUpdater.dayActivityTask) { dayActivityTask in
      try dayActivityTask.update(with: action)
      return OperateResult(leafAction: action, type: .updateDayActivityTask(dayActivityTask), result: decisionResult(for: action.actionId))
    }
  }

  private func deleteDayActivityTask(action: ManageActivityAction) async -> OperateResult {
    await operateOnObject(for: action, fetcher: dayUpdater.dayActivityTask) { dayActivityTask in
      OperateResult(leafAction: action, type: .deleteDayActivityTask(dayActivityTask), result: decisionResult(for: action.actionId))
    }
  }

  // MARK: - Activity

  private func getActivityTemplates(action: ManageActivityAction) async -> OperateResult {
    do {
      let activities = try await activityRepository.loadActivities()
      return OperateResult(action, fetchResult: .fetched(activities.map(ActivityTemplateRequest.init)))
    } catch {
      return OperateResult(action, fetchResult: .failed(errorMessage: error.localizedDescription))
    }
  }

  private func getActivityTemplate(action: ManageActivityAction) async -> OperateResult {
    await operateOnObject(for: action, fetcher: activityRepository.getActivity) { activity in
      OperateResult(action, fetchResult: .fetched(ActivityTemplateRequest(activity: activity)))
    }
  }

  private func createActivityTemplate(
    action: ManageActivityAction,
    nextActions: inout [ManageActivityAction]
  ) async -> (decision: Decision?, results: [OperateResult]) {
    do {
      var activity: Activity
      if let decisionResult = decisionResult(for: action.actionId),
         decisionResult == .accepted,
         let identifier = action.fields?["identifier"]?.stringValue,
         let createdActivity = try await activityRepository.getActivity(identifier: identifier) {
        activity = createdActivity
      } else {
        activity = try await Activity(
          uuid: uuid,
          action: action,
          tagRepository: tagRepository,
          activityLabelRepository: activityLabelRepository,
          iconRepository: iconRepository
        )
      }

      let (decisions, operateResults) = await handleConnectedActions(for: &activity, nextActions: &nextActions)
      let decision: Decision = decisions.isEmpty
      ? .leaf(DecisionParameters(action, type: .createActivity(activity), result: decisionResult(for: action.actionId)))
      : .chain(DecisionParameters(action, type: .createActivity(activity), result: decisionResult(for: action.actionId)), nextDecisions: decisions)
      return (decision: decision, results: operateResults)
    } catch {
      let result = OperateResult(action, fetchResult: .failed(errorMessage: error.localizedDescription))
      return (decision: nil, results: [result])
    }
  }

  private func handleConnectedActions(
    for activity: inout Activity,
    nextActions: inout [ManageActivityAction]
  ) async -> ([Decision], [OperateResult]) {
    var decisions: [Decision] = []
    var operateResults: [OperateResult] = []
    for nextAction in nextActions {
      if case .createActivityTemplateTask = nextAction.action {
        let activityId = nextAction.fields?["activityTemplateIdentifier"]?.uuidValue
        guard activityId == activity.id else { continue }
        if let index = nextActions.firstIndex(of: nextAction) {
          nextActions.remove(at: index)
        }

        do {
          var activityTask: ActivityTask
          if let decisionResult = decisionResult(for: nextAction.actionId),
             decisionResult == .accepted,
             let identifier = nextAction.fields?["identifier"]?.stringValue,
             let createdActivityTask = try await activityRepository.activityTask(identifier) {
            activityTask = createdActivityTask
          } else {
            activityTask = try ActivityTask(uuid: uuid, action: nextAction)
          }

          decisions.append(.leaf(DecisionParameters(nextAction, type: .createActivityTask(activity, activityTask), result: decisionResult(for: nextAction.actionId))))
        } catch {
          operateResults.append(OperateResult(nextAction, fetchResult: .failed(errorMessage: error.localizedDescription)))
        }
      } else if case .createDayActivity = nextAction.action {
        let activityId = nextAction.fields?["templateIdentifier"]?.uuidValue
        guard activityId == activity.id else { continue }
        if let index = nextActions.firstIndex(of: nextAction) {
          nextActions.remove(at: index)
        }

        let (decision, results) = await createDayActivity(
          action: nextAction,
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

  private func updateActivityTemplate(action: ManageActivityAction) async -> OperateResult {
    await operateOnObject(for: action, fetcher: activityRepository.getActivity) { activity in
      try await activity.update(
        with: action,
        uuid: uuid,
        tagRepository: tagRepository,
        activityLabelRepository: activityLabelRepository,
        iconRepository: iconRepository
      )
      return OperateResult(leafAction: action, type: .updateActivity(activity), result: decisionResult(for: action.actionId))
    }
  }

  private func deleteActivityTemplate(action: ManageActivityAction) async -> OperateResult {
    await operateOnObject(for: action, fetcher: activityRepository.getActivity) { activity in
      OperateResult(leafAction: action, type: .deleteActivity(activity), result: decisionResult(for: action.actionId))
    }
  }

  // MARK: - ActivityTask

  private func createActivityTaskTemplate(action: ManageActivityAction) async -> OperateResult {
    do {
      let activityTask = try ActivityTask(uuid: uuid, action: action)
      guard var activity = try await activityRepository.activity(.id(activityTask.activityId.uuidString)) else {
        throw NSError(domain: "Activity not found: \(activityTask.activityId)", code: 7777)
      }
      activity.tasks.append(activityTask)
      return OperateResult(leafAction: action, type: .createActivityTask(activity, activityTask), result: decisionResult(for: action.actionId))
    } catch {
      return OperateResult(action, fetchResult: .failed(errorMessage: error.localizedDescription))
    }
  }

  private func updateActivityTaskTemplate(action: ManageActivityAction) async -> OperateResult {
    await operateOnObject(for: action, fetcher: activityRepository.activityTask) { activityTask in
      try activityTask.update(with: action)
      guard var activity = try await activityRepository.activity(.id(activityTask.activityId.uuidString)) else {
        throw NSError(domain: "Activity not found: \(activityTask.activityId)", code: 7777)
      }
      activity.tasks.removeAll { $0.id == activityTask.id }
      activity.tasks.append(activityTask)
      return OperateResult(leafAction: action, type: .updateActivityTask(activity, activityTask), result: decisionResult(for: action.actionId))
    }
  }

  private func deleteActivityTaskTemplate(action: ManageActivityAction) async -> OperateResult {
    await operateOnObject(for: action, fetcher: activityRepository.activityTask) { activityTask in
      guard var activity = try await activityRepository.activity(.id(activityTask.activityId.uuidString)) else {
        throw NSError(domain: "Activity not found: \(activityTask.activityId)", code: 7777)
      }
      activity.tasks.removeAll { $0.id == activityTask.id }
      return OperateResult(leafAction: action, type: .deleteActivityTask(activity, activityTask), result: decisionResult(for: action.actionId))
    }
  }

  private func getTags(action: ManageActivityAction) async -> OperateResult {
    do {
      let tags = try await tagRepository.loadTags([])
      return OperateResult(action, fetchResult: .fetched(tags.map(MarkerRequest.init)))
    } catch {
      return OperateResult(action, fetchResult: .failed(errorMessage: error.localizedDescription))
    }
  }

  // MARK: - Helpers

  private func operateOnObject<T>(
    for action: ManageActivityAction,
    fetcher: @escaping (String) async throws -> T?,
    operate: @escaping (inout T) async throws -> OperateResult
  ) async -> OperateResult {
    do {
      guard let objectId = action.fields?["identifier"]?.stringValue else {
        throw NSError(domain: "[\(action.actionId)] fieldsNotFound: identifier", code: 9999)
      }
      guard var object = try await fetcher(objectId) else {
        throw NSError(domain: "[\(action.actionId)] objectNotFound: \(objectId)", code: 8888)
      }
      return try await operate(&object)
    } catch {
      return OperateResult(action, fetchResult: .failed(errorMessage: error.localizedDescription))
    }
  }

  private func accept(
    _ action: ManageActivityAction,
    objectId: String,
    operate: @escaping () async throws -> Void
  ) async -> ManageActivityActionResultRequest {
    do {
      try await operate()
      let result = ManageActivityActionResultRequest(
        action: action,
        decisionResult: .success(objectId)
      )
      return result
    } catch {
      let result = ManageActivityActionResultRequest(
        action: action,
        decisionResult: .failed(errorMessage: "can not perform operation: \(error.localizedDescription)")
      )
      return result
    }
  }

  private mutating func setDecisionResults(_ decisionResults: [ManageActivityActionResultRequest]) {
    self.decisionResults = decisionResults
  }

  private func decisionResult(for actionId: String) -> DecisionParameters.DecisionResult? {
    guard let decisionResult = decisionResults.first(where: { $0.actionId == actionId })?.decisionResult else { return nil }
    return DecisionParameters.DecisionResult(decisionResult)
  }
}
