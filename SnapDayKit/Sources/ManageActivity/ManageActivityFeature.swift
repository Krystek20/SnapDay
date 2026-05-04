import Foundation
import ComposableArchitecture
import Common
import Repositories
import Utilities
import Models
import AIModule

import struct UiComponents.ListItem

@Reducer
public struct ManageActivityFeature: TodayProvidable {

  // MARK: - Dependecies

  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.uuid) private var uuid
  @Dependency(\.webSocket) private var webSocket

  private let speechAnalyzer = SpeechAnalyzer()

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    public enum BottomSection {
      case confirmButton(isDisabled: Bool)
      case cancelButton
      case acceptDiscardButtons
      case done
    }

    public enum Field: Hashable {
      case request
    }
    var focus: Field? = .request

    var transcribedText = ""

    var bottomSection: BottomSection {
      if (actionsResult?.decisions.all.allSatisfy { $0.parameters.result != nil }) ?? false {
        .done
      } else if actionsResult?.decisions.isEmpty == false {
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

    var listItemsSections: [DecisionListItemSection] {
      guard let decisions = actionsResult?.decisions else { return [] }
      return [DecisionListItemSection](decisions: decisions)
    }

    var isListening = false
    var isThinking = false

    var actionsResult: ActionsResult?

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
      case discardButtonTapped
      case doneButtonTapped
      case listItemTapped(String, ListItem)
    }
    public enum InternalAction: Equatable {
      case startSpeaking
      case stopSpeaking(String)
      case connection(ConnectionAction)
      case setActionsResult(ActionsResult)
      case handleReceivedMessage(ManageActivitiesEvent)
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
      case .view(.cancelButtonTapped),
          .view(.doneButtonTapped):
          .run { _ in
            await dismiss()
          }
      case .view(.acceptButtonTapped):
        acceptAll(state: &state)
      case .view(.discardButtonTapped):
        discardAll(state: &state)
      case .view(.listItemTapped(let actionId, let listItem)):
        handleListItemAction(state: &state, actionId: actionId, listItem: listItem)
      case .internal(.startSpeaking):
        startSpeaking(state: &state)
      case .internal(.stopSpeaking(let text)):
        stopSpeaking(state: &state, text: text)
      case .internal(.connection(let action)):
        handleConnectionAction(state: &state, action: action)
      case .internal(.handleReceivedMessage(let message)):
        handleReceivedMessage(state: &state, message: message)
      case .internal(.setActionsResult(let actionsResult)):
        setActionsResult(state: &state, actionsResult: actionsResult)
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
//    let data = test.data(using: .utf8)!
//    let decoder = JSONDecoder()
//    decoder.dateDecodingStrategy = .iso8601
//    do {
//      let request = try decoder .decode(ManageActivitiesRequest.self, from: data)
//      return handleActions(state: &state, actions: request.actions)
//    } catch {
//      print("error: \(error)")
//      return .none
//    }
  }

  private func handleConnectionAction(state: inout State, action: Action.ConnectionAction) -> Effect<Action> {
    switch action {
    case .connect:
      do {
        let url = try URLProvider.url(for: "/api/v1/manage-activities", isWebSocket: true)
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
      } catch {
        print("error: \(error.localizedDescription)")
        return .none
      }
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
      let request = ManageActivitiesResponse(message: message, userContext: UserContext(now: .now))
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
    case .actions(let request):
      print("ReceivedMessage: .request(\(request)")
      return handleActions(state: &state, actions: request.actions)
    case .tools(let tools):
      print("ReceivedMessage: .tools(\(tools)")
      return handleTools(state: &state, tools: tools)
    }
  }

  private func handleActions(state: inout State, actions: [ManageActivityAction]) -> Effect<Action> {
    .run { send in
      guard !actions.isEmpty else {
        return await dismiss()
      }

      let actionParser = ActionParser()
      let actionsResult = await actionParser.parse(actions: actions)
      await send(.internal(.setActionsResult(actionsResult)))
    }
  }

  private func setActionsResult(state: inout State, actionsResult: ActionsResult) -> Effect<Action> {
    if actionsResult.decisions.isEmpty {
      state.actionsResult = nil
      return .send(.internal(.connection(.send(.userResponse(actionsResult.results)))))
    } else {
      state.actionsResult = actionsResult
      return .none
    }
  }

  private func handleTools(state: inout State, tools: [ToolRequest]) -> Effect<Action> {
    .run { send in
      let toolParser = ToolParser()
      let toolsResponse = await toolParser.actions(on: tools)
      await send(.internal(.connection(.send(.toolResponse(toolsResponse)))))
    }
  }

  private func handleListItemAction(state: inout State, actionId: String, listItem: ListItem) -> Effect<Action> {
    let decision = state.actionsResult?.decisions.all.first(where: { $0.parameters.action.actionId == listItem.id })
    guard let decision else {
      return .none
    }

    return if let action = ListItemRowAction(rawValue: actionId) {
      switch action {
      case .accept:
        accept(state: &state, decision: decision, acceptAll: false)
      case .discard:
        discard(state: &state, decision: decision)
      }
    } else if let action = ListItemHeaderAction(rawValue: actionId) {
      switch action {
      case .acceptAll:
        accept(state: &state, decision: decision, acceptAll: true)
      }
    } else {
      .none
    }
  }

  private func accept(state: inout State, decision: Decision, acceptAll: Bool) -> Effect<Action> {
    .run { [actionsResult = state.actionsResult] send in
      guard let actionsResult else {
        throw NSError(domain: "Actions result is nil", code: -1000)
      }
      var actionParser = ActionParser()
      let updatedActionsResult = await actionParser.accept(
        decision,
        actionsResult: actionsResult,
        acceptAll: acceptAll,
        today: today
      )
      await send(.internal(.setActionsResult(updatedActionsResult)))
    }
  }

  private func acceptAll(state: inout State) -> Effect<Action> {
    .run { [actionsResult = state.actionsResult] send in
      guard let actionsResult else {
        throw NSError(domain: "Actions result is nil", code: -1000)
      }
      var actionParser = ActionParser()
      let updatedActionsResult = await actionParser.acceptAll(
        actionsResult: actionsResult,
        today: today
      )
      await send(.internal(.setActionsResult(updatedActionsResult)))
    }
  }

  private func discard(state: inout State, decision: Decision) -> Effect<Action> {
    .run { [actionsResult = state.actionsResult] send in
      guard let actionsResult else {
        throw NSError(domain: "Actions result is nil", code: -1000)
      }
      var actionParser = ActionParser()
      let updatedActionsResult = await actionParser.discard(decision, actionsResult: actionsResult)
      await send(.internal(.setActionsResult(updatedActionsResult)))
    }
  }

  private func discardAll(state: inout State) -> Effect<Action> {
    .run { [actionsResult = state.actionsResult] send in
      guard let actionsResult else {
        throw NSError(domain: "Actions result is nil", code: -1000)
      }
      var actionParser = ActionParser()
      let updatedActionsResult = await actionParser.discardAll(actionsResult: actionsResult)
      await send(.internal(.setActionsResult(updatedActionsResult)))
    }
  }
}

let test = """
{
    "actions": [
        {
            "payload": {
                "updateDayActivity": {
                    "name": "Walk with dog — split: morning, afternoon, evening",
                    "tags": [
                        "pies"
                    ],
                    "position": 3,
                    "reference": {
                        "byIdentifier": "4D124B35-A578-4AE1-87CB-C0A1D6CEFF16"
                    },
                    "dueDate": null,
                    "icon": null,
                    "doneDate": null,
                    "overview": "15-minute walk with the dog split into three short walks (morning, afternoon, evening).",
                    "reminderDate": null,
                    "labels": [
                    ],
                    "duration": 45,
                    "date": "2026-02-22T00:00:00Z",
                    "important": false
                }
            },
            "actionId": "1"
        },
        {
            "payload": {
                "createDayActivityTask": {
                    "doneDate": null,
                    "name": "Morning 15‑minute walk",
                    "duration": 15,
                    "reference": {
                        "byActionId": "1"
                    },
                    "overview": null,
                    "position": 0,
                    "reminderDate": null
                }
            },
            "actionId": "2"
        },
        {
            "payload": {
                "createDayActivityTask": {
                    "doneDate": null,
                    "name": "Afternoon 15‑minute walk",
                    "duration": 15,
                    "reference": {
                        "byActionId": "1"
                    },
                    "overview": null,
                    "position": 1,
                    "reminderDate": null
                }
            },
            "actionId": "3"
        },
        {
            "payload": {
                "createDayActivityTask": {
                    "doneDate": null,
                    "name": "Evening 15‑minute walk",
                    "duration": 15,
                    "reference": {
                        "byActionId": "1"
                    },
                    "overview": null,
                    "position": 2,
                    "reminderDate": null
                }
            },
            "actionId": "4"
        }
    ],
    "_thinking": "Validated existing DayActivity and will update its name/overview and add three tasks of 15 minutes each. References use the existing activity identifier for the update and action-scoped reference for the new tasks.",
    "error": "NONE"
}
"""

extension DecisionType {

  private func formattedDay(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMMM yyyy"
    formatter.locale = .preferred
    return formatter.string(from: date)
  }

  var title: String {
    switch self {
    case .createDayActivity(let dayActivity):
      if let date = dayActivity.date {
        String(localized: "Create a new activity for \(formattedDay(date))", bundle: .module)
      } else {
        String(localized: "Create a new day activity", bundle: .module)
      }
    case .updateDayActivity(let dayActivity):
      if let date = dayActivity.date {
        String(localized: "Update the activity for \(formattedDay(date))", bundle: .module)
      } else {
        String(localized: "Update this day activity", bundle: .module)
      }
    case .deleteDayActivity(let dayActivity):
      if let date = dayActivity.date {
        String(localized: "Delete the activity for \(formattedDay(date))", bundle: .module)
      } else {
        String(localized: "Delete this day activity", bundle: .module)
      }
    case .createDayActivityTask(let dayActivity, let dayActivityTask):
      if let date = dayActivity.date {
        String(localized: "Add a new task to \(dayActivity.name) for \(formattedDay(date))", bundle: .module)
      } else {
        String(localized: "Add a new task to \(dayActivity.name)", bundle: .module)
      }
    case .updateDayActivityTask(let dayActivityTask):
      String(localized: "Update this task in the day activity", bundle: .module )
    case .deleteDayActivityTask(let dayActivityTask):
      String(localized: "Remove this task from the day activity", bundle: .module)
    case .createActivity(let activity):
      String(localized: "Create a new saved activity", bundle: .module)
    case .updateActivity(let activity):
      String(localized: "Update this saved activity", bundle: .module)
    case .deleteActivity(let activity):
      String(localized: "Delete this saved activity", bundle: .module)
    case .createActivityTask(let activity, let activityTask):
      String(localized: "Add a new task to saved \(activity.name)", bundle: .module)
    case .updateActivityTask(let activity, let activityTask):
      String(localized: "Update this task in saved \(activity)", bundle: .module)
    case .deleteActivityTask(let activity, let activityTask):
      String(localized: "Remove this task from saved \(activity.name)", bundle: .module)
    }
  }
}
