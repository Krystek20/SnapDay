import Foundation
import ComposableArchitecture
import Common
import Repositories
import Utilities
import Models
import AIModule

import struct UiComponents.ListItem
import struct UiComponents.ListTrailingMenuItem

@Reducer
public struct ManageActivityFeature {

  // MARK: - Dependecies

  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.webSocket) private var webSocket

  @Dependency(\.activityRepository) var activityRepository
  @Dependency(\.dayActivityRepository) var dayActivityRepository

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
      case create(DayActivity, UUID)
    }
    var userDecision: UserDecision?

    public enum Field: Hashable {
      case request
    }
    var focus: Field? = .request

//    var transcribedText = "Dodaj spacer z Harleyem na środę z przypomnieniem o 19 i oznacz jako ważne"
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
      case .create(let dayActivity, _):

        let isDone = dayActivity.doneDate != nil
        var participants: [ListItem.Participant] = []
        if let share = dayActivity.share, !share.participants.filter(\.isShared).isEmpty {
          participants = share.participants.map {
            ListItem.Participant(id: $0.id, name: $0.name)
          }
        }

        var progress = ListItem.Progress.none
        if !dayActivity.dayActivityTasks.isEmpty {
          let doneTasks = dayActivity.dayActivityTasks.filter(\.isDone).count
          let totalTasks = dayActivity.dayActivityTasks.count
          progress = .line(value: Double(doneTasks), total: Double(totalTasks))
        }

        return UserDecisionCard(
          title: "Create new activity?",
          subtitle: "SnapDay AI prepared this action for you",
          item: ListItem(
            id: dayActivity.id.uuidString,
            parentId: nil,
            title: dayActivity.name,
            subtitle: SubtitleFormatter.format(
              overview: dayActivity.overview,
              duration: dayActivity.totalDuration
            ),
            fieldType: .text,
            iconType: .iconId(dayActivity.iconId),
            isStrikethrough: isDone,
            displayedIcons: [
              dayActivity.important ? .exclamationmark : nil,
              dayActivity.dueDate != nil ? .hourglass : nil,
              dayActivity.reminderDate != nil ? .bell : nil
            ].compactMap { $0 },
            participants: participants,
            divider: .none,
            isDraggable: false,
            priority: .normal,
            trailing: .none,
            progress: progress
          )
        )
      case nil:
        return nil
      }
    }

    var isListening = false
    var isThinking = false

    @ObservationStateIgnored
    var queue: [ManageActivityAction] = []

    @ObservationStateIgnored
    var responses: [String] = []

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
      case handleManageActivitiesResponse(ManageActivitiesResponse)
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
      case finishAction(String)
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
      case .internal(.handleManageActivitiesResponse(let response)):
        handleManageActivitiesResponse(state: &state, response: response)
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
      return .send(.internal(.handleManageActivitiesResponse(response)))
    }
  }

  private func handleManageActivitiesResponse(state: inout State, response: ManageActivitiesResponse) -> Effect<Action> {
    .send(.internal(.flow(.start(response.actions))))
  }

  private func setUserDecision(state: inout State, userDecision: State.UserDecision) -> Effect<Action> {
    state.userDecision = userDecision
    return .none
  }

  private func acceptUserDecision(state: inout State) -> Effect<Action> {
    defer { state.userDecision = nil }
    return switch state.userDecision {
    case .create(let dayActivity, let actionId):
        .run { send in
          try await dayActivityRepository.saveDayActivity(dayActivity)
          await send(.internal(.flow(.finishAction("createDayActivity_actionId:\(actionId)_created_id:\(dayActivity.id)"))))
        }
    case .none:
        .none
    }
  }

  private func discardUserDecision(state: inout State) -> Effect<Action> {
    defer { state.userDecision = nil }
    return switch state.userDecision {
    case .create(_, let actionId):
        .run { send in
          await send(.internal(.flow(.finishAction("createDayActivity_actionId:\(actionId)_userCancelled"))))
        }
    case .none:
        .none
    }
  }

  private func handleFlow(state: inout State, flow: Action.Flow) -> Effect<Action> {
    switch flow {
    case .start(let actions):
      state.queue = actions
//      state.pending = nil
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
      switch action.action {

      case .getDayActivities:
          return .run { send in
            guard let date = ISO8601DateFormatter.utcDate(from: action.value) else {
              print("NO DATE FOR \(action.value)")
              return
            }
            let configuration = ActivitiesFetchConfiguration(range: date...date)
            let dayActivities = try await dayActivityRepository.dayActivities(configuration: configuration)
            let result = "getDayActivities_actionId:\(action.actionId)_[\(dayActivities.rawString)]"
            await send(.internal(.flow(.finishAction(result))))
          }

      case .getDayActivity:
        return .run { [action] send in
          guard let dayActivityId = action.value,
                let dayActivity = try await dayActivityRepository.activity(identifier: dayActivityId) else {
            print("NO dayActivityId: \(action.value)")
            return
          }
          let result = "getDayActivity_actionId:\(action.actionId)_[\(dayActivity.rawString)]"
          await send(.internal(.flow(.finishAction(result))))
        }

      case .createDayActivity:
        return .run { [action] send in
          guard let fields = action.fields,
                let data = fields.data(using: .utf8),
                let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("NO fields: \(action.fields)")
            return
          }

          if let dayActivity = DayActivity(dictionary: dictionary, activity: nil) {
            print("New day activity: \(dayActivity)")
            await send(.internal(.setUserDecision(.create(dayActivity, action.actionId))))
          } else {
            await send(.internal(.flow(.finishAction("createDayActivity_actionId:\(action.actionId)_failed"))))
          }
        }

      case .updateDayActivity:
        return .none

      case .getActivityTemplates:
        return .run { send in
            let activities = try await activityRepository.loadActivities()
            let rawActivities = activities
              .map { "{name:\($0.name);id:\($0.id)}" }
              .joined(separator: ",")
            let result = "getActivityTemplates:[\(rawActivities)]"
            await send(.internal(.flow(.finishAction(result))))
          }
      case .deleteDayActivity:
        return .none
      case .createDayActivityTask:
        return .run { [action] send in
          guard let fields = action.fields,
                let data = fields.data(using: .utf8),
                let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("NO fields: \(action.fields)")
            return
          }
          if let dayActivityTask = DayActivityTask(dictionary: dictionary, dayActivityId: action.value) {
            print("New day activity task: \(dayActivityTask)")
            await send(.internal(.flow(.finishAction("createDayActivityTask_actionId:\(action.actionId)_created_id:\(dayActivityTask.id)"))))
          } else {
            await send(.internal(.flow(.finishAction("createDayActivityTask_actionId:\(action.actionId)_failed"))))
          }
          //          try await dayActivityRepository.saveDayActivity(newActivity)
        }

      case .updateDayActivityTask:
        return .none
      case .deleteDayActivityTask:
        return .none
      case .getActivityTemplate:
        return .none
      case .createActivityTemplate:
        return .none
      case .updateActivityTemplate:
        return .none
      case .deleteActivityTemplate:
        return .none
      case .createActivityTemplateTask:
        return .none
      case .updateActivityTemplateTask:
        return .none
      case .deleteActivityTemplateTask:
        return .none
      case .getTags:
        return .none
      case .createTag:
        return .none
      case .createLabel:
        return .none
      case .createRGBColor:
        return .none
      case .createIcon:
        return .none
      }
    case .finishAction(let result):
      state.responses.append(result)
      return .send(.internal(.flow(.processNext)))
    }
  }
}

extension [DayActivity] {
  var rawString: String {
      map { "{name:\($0.name);id:\($0.id)}" }
      .joined(separator: ",")
  }
}

extension DayActivity {

  #warning("Tags and Labels and dayActivityTasks are not handled yet")
  init?(dictionary: [String: Any], activity: Activity?) {
    guard let name = dictionary["name"] as? String,
          let date = ISO8601DateFormatter.utcDate(from: dictionary["date"] as? String) else { return nil }
    self.init(
      id: UUID(),
      date: date,
      activity: activity,
      name: name,
      iconId: dictionary["iconIdentifier"] as? UUID,
      dueDate: ISO8601DateFormatter.utcDate(from: dictionary["dueDate"] as? String),
      doneDate: ISO8601DateFormatter.utcDate(from: dictionary["doneDate"] as? String),
      duration: dictionary["duration"] as? Int ?? .zero,
      overview: dictionary["overview"] as? String,
      isGeneratedAutomatically: false,
      reminderDate: ISO8601DateFormatter.utcDate(from: dictionary["reminderDate"] as? String),
      important: dictionary["important"] as? Bool ?? false,
      position: dictionary["position"] as? Int ?? -1
    )
  }

  var rawString: String {
    var rawDayActivity = "{"
    rawDayActivity += "date:\(date, default: "Nil");"
    rawDayActivity += "doneDate:\(doneDate, default: "Nil");"
    rawDayActivity += "dueDate:\(dueDate, default: "Nil");"
    rawDayActivity += "duration:\(duration);"
    rawDayActivity += "iconIdentifier:\(iconId, default: "Nil");"
    rawDayActivity += "identifier:\(id);"
    rawDayActivity += "important:\(important);"
    let rawLabels = labels.map { "id:\($0.id);name:\($0.name);" }.joined(separator: ",")
    rawDayActivity += "labels:[\(rawLabels)];"
    let rawTags = tags.map { "id:\($0.id);name:\($0.name);" }.joined(separator: ",")
    rawDayActivity += "tags:[\(rawTags)];"
    rawDayActivity += "name:\(name);"
    rawDayActivity += "overview:\(overview, default: "Nil");"
    rawDayActivity += "position:\(position);"
    rawDayActivity += "reminderDate:\(reminderDate, default: "Nil");"
    rawDayActivity += "templateIdentifier:\(activity?.id, default: "Nil");"
    let rawDayActivityTasks = dayActivityTasks.map { "id:\($0.id);name:\($0.name);" }.joined(separator: ",")
    rawDayActivity += "dayActivityTasks:[\(rawDayActivityTasks)];"
    rawDayActivity += "}"
    return rawDayActivity
  }
}

extension DayActivityTask {

#warning("ActivityTask is not handled yet")
  init?(dictionary: [String: Any], dayActivityId: String?) {
    guard let name = dictionary["name"] as? String,
          let dayActivityId = UUID(uuidString: dayActivityId ?? "") else { return nil }
    self.init(
      id: UUID(),
      dayActivityId: dayActivityId,
      activityTask: nil,
      name: name,
      doneDate: ISO8601DateFormatter.utcDate(from: dictionary["doneDate"] as? String),
      duration: dictionary["duration"] as? Int ?? .zero,
      overview: dictionary["overview"] as? String,
      reminderDate: ISO8601DateFormatter.utcDate(from: dictionary["reminderDate"] as? String),
      position: dictionary["position"] as? Int ?? -1
    )
  }
}
