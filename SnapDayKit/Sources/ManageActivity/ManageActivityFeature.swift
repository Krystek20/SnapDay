import Foundation
import ComposableArchitecture
import Common
import Repositories
import Utilities
import Models
import AIModule

import struct UiComponents.ListItem
import struct UiComponents.Marker

@Reducer
public struct ManageActivityFeature: TodayProvidable {

  // MARK: - Dependecies

  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.uuid) private var uuid
  @Dependency(\.webSocket) private var webSocket

  @Dependency(\.activityRepository) private var activityRepository
  @Dependency(\.tagRepository) private var tagRepository
  @Dependency(\.activityLabelRepository) private var activityLabelRepository
  @Dependency(\.iconRepository) private var iconRepository
  @Dependency(\.dayUpdater) private var dayUpdater
  @Dependency(\.utcCalendar) var calendar

  private let speechAnalyzer = SpeechAnalyzer()

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    public enum BottomSection {
      case confirmButton(isDisabled: Bool)
      case cancelButton
      case acceptDiscardButtons
    }

    public enum UserDecision: Equatable {
      case createDayActivity(DayActivity, ManageActivityAction)
      case updateDayActivity(DayActivity, ManageActivityAction)
      case deleteDayActivity(DayActivity, ManageActivityAction)
      case createDayActivityTask(DayActivity, DayActivityTask, ManageActivityAction)
      case updateDayActivityTask(DayActivityTask, ManageActivityAction)
      case deleteDayActivityTask(DayActivityTask, ManageActivityAction)
      case createActivity(Activity, ManageActivityAction)
      case updateActivity(Activity, ManageActivityAction)
      case deleteActivity(Activity, ManageActivityAction)
      case createActivityTask(Activity, ActivityTask, ManageActivityAction)
      case updateActivityTask(Activity, ActivityTask, ManageActivityAction)
      case deleteActivityTask(Activity, ActivityTask, ManageActivityAction)
    }
    var userDecision: UserDecision?

    public enum Field: Hashable {
      case request
    }
    var focus: Field? = .request

    var transcribedText = ""

    var bottomSection: BottomSection {
      if userDecisionCard != nil {
        .acceptDiscardButtons
      } else if isThinking {
        .cancelButton
      } else {
        .confirmButton(isDisabled: transcribedText.isEmpty || isListening || isThinking)
      }
    }

    var isTextFieldDisabled: Bool {
      isListening || isThinking
    }

    var showProcessingState: Bool {
      isThinking
    }

    var userDecisionCard: UserDecisionCard? {
      switch userDecision {
      case .createDayActivity(let dayActivity, _):
        UserDecisionCard(
          title: "Create new activity?",
          subtitle: "SnapDay AI prepared this action for you",
          item: ListItem(dayActivity: dayActivity)
        )
      case .updateDayActivity(let dayActivity, _):
        UserDecisionCard(
          title: "Update existing activity?",
          subtitle: "SnapDay AI prepared this action for you",
          item: ListItem(dayActivity: dayActivity)
        )
      case .deleteDayActivity(let dayActivity, _):
        UserDecisionCard(
          title: "Delete existing activity?",
          subtitle: "SnapDay AI prepared this action for you",
          item: ListItem(dayActivity: dayActivity)
        )
      case .createDayActivityTask(_, let dayActivityTask, _):
        UserDecisionCard(
          title: "Create new task?",
          subtitle: "SnapDay AI prepared this task for you",
          item: ListItem(dayActivityTask: dayActivityTask)
        )
      case .updateDayActivityTask(let dayActivityTask, _):
        UserDecisionCard(
          title: "Update existing task?",
          subtitle: "SnapDay AI updated this task for you",
          item: ListItem(dayActivityTask: dayActivityTask)
        )
      case .deleteDayActivityTask(let dayActivityTask, _):
        UserDecisionCard(
          title: "Delete existing task?",
          subtitle: "SnapDay AI prepared this task for you",
          item: ListItem(dayActivityTask: dayActivityTask)
        )
      case .createActivity(let activity, _):
        UserDecisionCard(
          title: "Create new template?",
          subtitle: "SnapDay AI prepared this task for you",
          item: ListItem(activity: activity)
        )
      case .updateActivity(let activity, _):
        UserDecisionCard(
          title: "Update existing template?",
          subtitle: "SnapDay AI prepared this task for you",
          item: ListItem(activity: activity)
        )
      case .deleteActivity(let activity, _):
        UserDecisionCard(
          title: "Delete existing template?",
          subtitle: "SnapDay AI prepared this task for you",
          item: ListItem(activity: activity)
        )
      case .createActivityTask(_, let activityTask, _):
        UserDecisionCard(
          title: "Create new template task?",
          subtitle: "SnapDay AI prepared this task for you",
          item: ListItem(activityTask: activityTask)
        )
      case .updateActivityTask(_, let activityTask, _):
        UserDecisionCard(
          title: "Update existing template task?",
          subtitle: "SnapDay AI prepared this task for you",
          item: ListItem(activityTask: activityTask)
        )
      case .deleteActivityTask(_, let activityTask, _):
        UserDecisionCard(
          title: "Delete existing template task?",
          subtitle: "SnapDay AI prepared this task for you",
          item: ListItem(activityTask: activityTask)
        )
      case nil:
        nil
      }
    }

    var isListening = false
    var isThinking = false

    @ObservationStateIgnored
    var queue: [ManageActivityAction] = []

    @ObservationStateIgnored
    var responses: [ManageActivityActionResultRequest] = []

    @ObservationStateIgnored
    var connection: WebSocketConnection?

    @ObservationStateIgnored
    var isConnected = false

    public init() { }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {
    public enum ViewAction: Equatable {
      case micButtonTapped
      case cancelButtonTapped
      case confirmButtonTapped
      case acceptButtonTapped
      case discardButtonPressed
    }
    public enum InternalAction: Equatable {
      case startSpeaking
      case stopSpeaking(String)
      case connection(ConnectionAction)
      case flow(Flow)
      case handleReceivedMessage(ManageActivitiesEvent)
      case setUserDecision(State.UserDecision)
    }
    public enum DelegateAction: Equatable {
      case dataSelected(Data?)
    }

    public enum ConnectionAction: Equatable {
      case connect
      case connected(WebSocketConnection)
      case received(WebSocketClient.Message)
      case send(ManageActivitiesMessageType)
      case disconnected
    }

    public enum Flow: Equatable {
      case start([ManageActivityAction])
      case processNext
      case handle(ManageActivityAction)
      case finishAction(ManageActivityActionResultRequest)
    }

    case binding(BindingAction<State>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.micButtonTapped):
          .send(.internal(.startSpeaking))
      case .view(.confirmButtonTapped):
        connectAndProceed(state: &state)
      case .view(.cancelButtonTapped):
          .run { _ in
            await dismiss()
          }
      case .view(.acceptButtonTapped):
        acceptUserDecision(state: &state)
      case .view(.discardButtonPressed):
        discardUserDecision(state: &state)
      case .internal(.startSpeaking):
        startSpeaking(state: &state)
      case .internal(.stopSpeaking(let text)):
        stopSpeaking(state: &state, text: text)
      case .internal(.connection(let action)):
        handleConnectionAction(state: &state, action: action)
      case .internal(.handleReceivedMessage(let message)):
        handleReceivedMessage(state: &state, message: message)
      case .internal(.flow(let flow)):
        handleFlow(state: &state, flow: flow)
      case .internal(.setUserDecision(let userDecision)):
        setUserDecision(state: &state, userDecision: userDecision)
      case .delegate(.dataSelected):
          .none
      case .delegate:
          .none
      case .binding:
          .none
      }
    }
  }

  private func startSpeaking(state: inout State) -> Effect<Action> {
    state.isListening = true
    state.focus = nil
    return .run { send in
      let text = try await speechAnalyzer.start()
      await send(.internal(.stopSpeaking(text)))
    }
  }

  private func stopSpeaking(state: inout State, text: String) -> Effect<Action> {
    state.transcribedText = text
    state.isListening = false
    return .none
  }

  private func connectAndProceed(state: inout State) -> Effect<Action> {
    state.focus = nil
    state.isThinking = true
    return .send(.internal(.connection(.connect)))
  }

  private func handleConnectionAction(state: inout State, action: Action.ConnectionAction) -> Effect<Action> {
    switch action {
    case .connect:
      let path = "wss://relieved-manatee-wildly.ngrok-free.app/api/v1/manage-activities"
      guard let url = URL(string: path) else { return .none }
      let (connection, stream) = webSocket.connect(url)
      return .merge(
        .send(.internal(.connection(.connected(connection)))),
        .run { send in
          do {
            for try await message in stream {
              await send(.internal(.connection(.received(message))))
            }
            await send(.internal(.connection(.disconnected)))
          } catch {
            await send(.internal(.connection(.disconnected)))
          }
        }
      )
    case .connected(let connection):
      state.isConnected = true
      state.connection = connection
      return .none
    case .disconnected:
      state.isConnected = false
      state.connection = nil
      return .none
    case .received(let message):
      print(message)
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      switch message {
      case .text(let text):
        guard let data = text.data(using: .utf8) else { return .none }
        do {
          let response = try decoder.decode(ManageActivitiesEvent.self, from: data)
          return .send(.internal(.handleReceivedMessage(response)))
        } catch {
          print(error)
          return .none
        }
      case .data(let data):
        do {
          let response = try decoder.decode(ManageActivitiesEvent.self, from: data)
          return .send(.internal(.handleReceivedMessage(response)))
        } catch {
          print(error)
          return .none
        }
      }
    case .send(let message):
      guard let connection = state.connection else { return .none }
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let request = ManageActivitiesRequest(message: message, userContext: UserContext(now: .now))
      do {
        let data = try encoder.encode(request)
        guard let string = String(data: data, encoding: .utf8) else {
          return .none
        }
        return .run { _ in
          try await webSocket.send(connection, .text(string))
        }
      } catch {
        print(error)
        return .none
      }
    }
  }

  private func handleReceivedMessage(state: inout State, message: ManageActivitiesEvent) -> Effect<Action> {
    switch message {
    case .hello(let sessionId):
      print("ReceivedMessage: .hello(\(sessionId)")
      return .send(.internal(.connection(.send(.userRequest(state.transcribedText)))))
    case .error(let errorMessage):
      print("ReceivedMessage: .error(\(errorMessage)")
      return .none
    case .response(let response):
      print("ReceivedMessage: .response(\(response)")
      return .send(.internal(.flow(.start(response.actions))))
    }
  }

  private func setUserDecision(state: inout State, userDecision: State.UserDecision) -> Effect<Action> {
    state.userDecision = userDecision
    return .none
  }

  private func acceptUserDecision(state: inout State) -> Effect<Action> {
    defer { state.userDecision = nil }
    return switch state.userDecision {
    case .createDayActivity(let dayActivity, let action),
         .updateDayActivity(let dayActivity, let action):
      accept(action, objectId: dayActivity.id.uuidString) {
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
    case .deleteDayActivity(let dayActivity, let action):
      accept(action, objectId: dayActivity.id.uuidString) {
        try await dayUpdater.removeDayActivity(dayActivity)
      }
    case .createDayActivityTask(let dayActivity, let dayActivityTask, let action):
      accept(action, objectId: dayActivityTask.id.uuidString) {
        try await dayUpdater.saveDayActivity(dayActivity, syncSharable: true)
      }
    case .updateDayActivityTask(let dayActivityTask, let action):
      accept(action, objectId: dayActivityTask.id.uuidString) {
        try await dayUpdater.saveDayActivityTask(dayActivityTask, syncSharable: true)
      }
    case .deleteDayActivityTask(let dayActivityTask, let action):
      accept(action, objectId: dayActivityTask.id.uuidString) {
        try await dayUpdater.removeDayActivityTask(dayActivityTask)
      }
    case.createActivity(let activity, let action),
        .updateActivity(let activity, let action):
      accept(action, objectId: activity.id.uuidString) {
        try await tagRepository.saveTags(activity.tags)
        try await activityLabelRepository.saveLabels(activity.labels)
        try await activityRepository.saveActivity(activity)
        try await dayUpdater.updateDaysByUpdatedActivity(activity, from: today)
      }
    case.deleteActivity(let activity, let action):
      accept(action, objectId: activity.id.uuidString) {
        try await dayUpdater.updateDaysByRemovedActivity(activity, from: today)
        try await activityRepository.deleteActivity(activity)
      }
    case.createActivityTask(let activity, let activityTask, let action),
        .updateActivityTask(let activity, let activityTask, let action):
      accept(action, objectId: activityTask.id.uuidString) {
        try await activityRepository.saveActivity(activity)
        try await dayUpdater.updateDaysByUpdatedActivity(activity, from: today)
      }
    case.deleteActivityTask(let activity, let activityTask, let action):
      accept(action, objectId: activityTask.id.uuidString) {
        try await dayUpdater.updateDaysByUpdatedActivity(activity, from: today)
        try await activityRepository.deleteActivityTask(activityTask)
        try await activityRepository.saveActivity(activity)
      }
    case .none:
        .none
    }
  }

  private func discardUserDecision(state: inout State) -> Effect<Action> {
    defer { state.userDecision = nil }
    return switch state.userDecision {
    case .createDayActivity(_, let action),
        .updateDayActivity(_, let action),
        .deleteDayActivity(_, let action),
        .createDayActivityTask(_, _, let action),
        .updateDayActivityTask(_, let action),
        .deleteDayActivityTask(_, let action),
        .createActivity(_, let action),
        .updateActivity(_, let action),
        .deleteActivity(_, let action),
        .createActivityTask(_, _, let action),
        .updateActivityTask(_, _, let action),
        .deleteActivityTask(_, _, let action):
        .run { send in
          let result = ManageActivityActionResultRequest(
            action: action,
            resultType: .userCancelled
          )
          await send(.internal(.flow(.finishAction(result))))
        }
    case .none:
        .none
    }
  }

  private func handleFlow(state: inout State, flow: Action.Flow) -> Effect<Action> {
    switch flow {
    case .start(let actions):
      state.queue = actions
      guard !actions.isEmpty else {
        return .run { _ in
          await dismiss()
        }
      }
      return .send(.internal(.flow(.processNext)))
    case .processNext:
      guard let next = state.queue.first else {
        defer {
          state.queue.removeAll()
          state.responses.removeAll()
        }
        return .send(.internal(.connection(.send(.userResponse(state.responses)))))
      }
      state.queue.removeFirst()
      return .send(.internal(.flow(.handle(next))))
    case .handle(let action):
      return switch action.action {
      case .getDayActivities: getDayActivities(action: action)
      case .getDayActivity: getDayActivity(action: action)
      case .createDayActivity: createDayActivity(action: action)
      case .updateDayActivity: updateDayActivity(action: action)
      case .deleteDayActivity: deleteDayActivity(action: action)
      case .getActivityTemplates: getActivityTemplates(action: action)
      case .createDayActivityTask: createDayActivityTask(action: action)
      case .updateDayActivityTask: updateDayActivityTask(action: action)
      case .deleteDayActivityTask: deleteDayActivityTask(action: action)
      case .getActivityTemplate: getActivityTemplate(action: action)
      case .createActivityTemplate: createActivityTemplate(action: action)
      case .updateActivityTemplate: updateActivityTemplate(action: action)
      case .deleteActivityTemplate: deleteActivityTemplate(action: action)
      case .createActivityTemplateTask: createActivityTaskTemplate(action: action)
      case .updateActivityTemplateTask: updateActivityTaskTemplate(action: action)
      case .deleteActivityTemplateTask: deleteActivityTaskTemplate(action: action)
      case .getTags: getTags(action: action)
      }
    case .finishAction(let result):
      state.responses.append(result)
      return .send(.internal(.flow(.processNext)))
    }
  }

  private func getDayActivities(action: ManageActivityAction) -> Effect<Action> {
    .run { send in
      guard let iso8601Date = ISO8601DateFormatter.date(from: action.fields?["date"]?.stringValue) else {
        let result = ManageActivityActionResultRequest(
          action: action,
          resultType: .failed(errorMessage: "fieldsNotFound: date")
        )
        return await send(.internal(.flow(.finishAction(result))))
      }
      let date = calendar.dayFormat(iso8601Date)
      let configuration = ActivitiesFetchConfiguration(range: date...date)
      let dayActivities = try await dayUpdater.dayActivities(configuration: configuration)

      let result = ManageActivityActionResultRequest(
        action: action,
        resultType: .fetched(dayActivities.map(DayActivityRequest.init))
      )
      await send(.internal(.flow(.finishAction(result))))
    }
  }

  private func getDayActivity(action: ManageActivityAction) -> Effect<Action> {
    operateOnObject(
      for: action,
      fetcher: dayUpdater.dayActivity,
      operate: { dayActivity in
        let result = ManageActivityActionResultRequest(
          action: action,
          resultType: .fetched(DayActivityRequest(dayActivity: dayActivity))
        )
        return .internal(.flow(.finishAction(result)))
      }
    )
  }

  private func createDayActivity(action: ManageActivityAction) -> Effect<Action> {
    .run { send in
      do {
        let dayActivity = try await DayActivity(
          uuid: uuid,
          action: action,
          activityRepository: activityRepository,
          tagRepository: tagRepository,
          activityLabelRepository: activityLabelRepository,
          iconRepository: iconRepository,
          calendar: calendar
        )
        await send(.internal(.setUserDecision(.createDayActivity(dayActivity, action))))
      } catch {
        let result = ManageActivityActionResultRequest(
          action: action,
          resultType: .failed(errorMessage: error.localizedDescription)
        )
        await send(.internal(.flow(.finishAction(result))))
      }
    }
  }

  private func updateDayActivity(action: ManageActivityAction) -> Effect<Action> {
    operateOnObject(
      for: action,
      fetcher: dayUpdater.dayActivity,
      operate: { dayActivity in
        try await dayActivity.update(
          with: action,
          uuid: uuid,
          tagRepository: tagRepository,
          activityLabelRepository: activityLabelRepository,
          iconRepository: iconRepository
        )
        return .internal(.setUserDecision(.updateDayActivity(dayActivity, action)))
      }
    )
  }

  private func deleteDayActivity(action: ManageActivityAction) -> Effect<Action> {
    operateOnObject(
      for: action,
      fetcher: dayUpdater.dayActivity,
      operate: { dayActivity in
          .internal(.setUserDecision(.deleteDayActivity(dayActivity, action)))
      }
    )
  }

  private func getActivityTemplates(action: ManageActivityAction) -> Effect<Action> {
    .run { send in
      let activities = try await activityRepository.loadActivities()
      let result = ManageActivityActionResultRequest(
        action: action,
        resultType: .fetched(activities.map(ActivityTemplateRequest.init))
      )
      await send(.internal(.flow(.finishAction(result))))
    }
  }

  private func getActivityTemplate(action: ManageActivityAction) -> Effect<Action> {
    operateOnObject(
      for: action,
      fetcher: activityRepository.getActivity,
      operate: { activity in
        let result = ManageActivityActionResultRequest(
          action: action,
          resultType: .fetched(ActivityTemplateRequest(activity: activity))
        )
        return .internal(.flow(.finishAction(result)))
      }
    )
  }

  private func createActivityTemplate(action: ManageActivityAction) -> Effect<Action> {
    .run { send in
      do {
        let activity = try await Activity(
          uuid: uuid,
          action: action,
          tagRepository: tagRepository,
          activityLabelRepository: activityLabelRepository,
          iconRepository: iconRepository
        )
        await send(.internal(.setUserDecision(.createActivity(activity, action))))
      } catch {
        let result = ManageActivityActionResultRequest(
          action: action,
          resultType: .failed(errorMessage: error.localizedDescription)
        )
        await send(.internal(.flow(.finishAction(result))))
      }
    }
  }

  private func updateActivityTemplate(action: ManageActivityAction) -> Effect<Action> {
    operateOnObject(
      for: action,
      fetcher: activityRepository.getActivity,
      operate: { activity in
        try await activity.update(
          with: action,
          uuid: uuid,
          tagRepository: tagRepository,
          activityLabelRepository: activityLabelRepository,
          iconRepository: iconRepository
        )
        return .internal(.setUserDecision(.updateActivity(activity, action)))
      }
    )
  }

  private func deleteActivityTemplate(action: ManageActivityAction) -> Effect<Action> {
    operateOnObject(
      for: action,
      fetcher: activityRepository.getActivity,
      operate: { activity in
          .internal(.setUserDecision(.deleteActivity(activity, action)))
      }
    )
  }

  private func createActivityTaskTemplate(action: ManageActivityAction) -> Effect<Action> {
    .run { send in
      do {
        let activityTask = try ActivityTask(uuid: uuid, action: action)
        guard var activity = try await activityRepository.activity(.id(activityTask.activityId.uuidString)) else {
          throw NSError(domain: "Activity not found: \(activityTask.activityId)", code: -1)
        }
        activity.tasks.append(activityTask)
        await send(.internal(.setUserDecision(.createActivityTask(activity, activityTask, action))))
      } catch {
        let result = ManageActivityActionResultRequest(
          action: action,
          resultType: .failed(errorMessage: error.localizedDescription)
        )
        await send(.internal(.flow(.finishAction(result))))
      }
    }
  }

  private func updateActivityTaskTemplate(action: ManageActivityAction) -> Effect<Action> {
    operateOnObject(
      for: action,
      fetcher: activityRepository.activityTask,
      operate: { activityTask in
        try activityTask.update(with: action)
        guard var activity = try await activityRepository.activity(.id(activityTask.activityId.uuidString)) else {
          throw NSError(domain: "Activity not found: \(activityTask.activityId)", code: -1)
        }
        activity.tasks.removeAll { $0.id == activityTask.id }
        activity.tasks.append(activityTask)
        return .internal(.setUserDecision(.updateActivityTask(activity, activityTask, action)))
      }
    )
  }

  private func deleteActivityTaskTemplate(action: ManageActivityAction) -> Effect<Action> {
    operateOnObject(
      for: action,
      fetcher: activityRepository.activityTask,
      operate: { activityTask in
        guard var activity = try await activityRepository.activity(.id(activityTask.activityId.uuidString)) else {
          throw NSError(domain: "Activity not found: \(activityTask.activityId)", code: -1)
        }
        activity.tasks.removeAll { $0.id == activityTask.id }
        return .internal(.setUserDecision(.deleteActivityTask(activity, activityTask, action)))
      }
    )
  }

  private func getTags(action: ManageActivityAction) -> Effect<Action> {
    .run { send in
      let tags = try await tagRepository.loadTags([])
      let result = ManageActivityActionResultRequest(
        action: action,
        resultType: .fetched(tags.map(MarkerRequest.init))
      )
      await send(.internal(.flow(.finishAction(result))))
    }
  }

  private func createDayActivityTask(action: ManageActivityAction) -> Effect<Action> {
    .run { send in
      do {
        let dayActivityTask = try DayActivityTask(uuid: uuid, action: action)
        guard var dayActivity = try await dayUpdater.dayActivity(identifier: dayActivityTask.dayActivityId.uuidString) else {
          throw NSError(domain: "Day activity not found: \(dayActivityTask.dayActivityId)", code: -1)
        }
        dayActivity.dayActivityTasks.append(dayActivityTask)
        await send(.internal(.setUserDecision(.createDayActivityTask(dayActivity, dayActivityTask, action))))
      } catch {
        let result = ManageActivityActionResultRequest(
          action: action,
          resultType: .failed(errorMessage: error.localizedDescription)
        )
        await send(.internal(.flow(.finishAction(result))))
      }
    }
  }

  private func updateDayActivityTask(action: ManageActivityAction) -> Effect<Action> {
    operateOnObject(
      for: action,
      fetcher: dayUpdater.dayActivityTask,
      operate: { dayActivityTask in
        try dayActivityTask.update(with: action)
        return .internal(.setUserDecision(.updateDayActivityTask(dayActivityTask, action)))
      }
    )
  }

  private func deleteDayActivityTask(action: ManageActivityAction) -> Effect<Action> {
    operateOnObject(
      for: action,
      fetcher: dayUpdater.dayActivityTask,
      operate: { dayActivityTask in
          .internal(.setUserDecision(.deleteDayActivityTask(dayActivityTask, action)))
      }
    )
  }

  private func operateOnObject<T>(
    for action: ManageActivityAction,
    fetcher: @escaping (String) async throws -> T?,
    operate: @escaping (inout T) async throws -> Action
  ) -> Effect<Action> {
    .run { send in
      guard let objectId = action.fields?["identifier"]?.stringValue else {
        let result = ManageActivityActionResultRequest(
          action: action,
          resultType: .failed(errorMessage: "[\(action.actionId)] fieldsNotFound: identifier")
        )
        return await send(.internal(.flow(.finishAction(result))))
      }

      guard var object = try await fetcher(objectId) else {
        let result = ManageActivityActionResultRequest(
          action: action,
          resultType: .failed(errorMessage: "[\(action.actionId)] objectNotFound: \(objectId)")
        )
        return await send(.internal(.flow(.finishAction(result))))
      }

      do {
        await send(try await operate(&object))
      } catch {
        let result = ManageActivityActionResultRequest(
          action: action,
          resultType: .failed(errorMessage: error.localizedDescription)
        )
        await send(.internal(.flow(.finishAction(result))))
      }
    }
  }

  private func accept(
    _ action: ManageActivityAction,
    objectId: String,
    operate: @escaping () async throws -> Void
  ) -> Effect<Action> {
    .run { send in
      do {
        try await operate()
        let result = ManageActivityActionResultRequest(
          action: action,
          resultType: .success(objectId)
        )
        await send(.internal(.flow(.finishAction(result))))
      } catch {
        let result = ManageActivityActionResultRequest(
          action: action,
          resultType: .failed(errorMessage: "can not perform operation: \(error.localizedDescription)")
        )
        await send(.internal(.flow(.finishAction(result))))
      }
    }
  }
}
