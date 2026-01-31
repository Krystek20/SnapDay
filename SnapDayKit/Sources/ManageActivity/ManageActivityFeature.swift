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
    }

    public enum Field: Hashable {
      case request
    }
    var focus: Field? = .request

    var transcribedText = "a"

    var bottomSection: BottomSection {
      if actionsResult?.decisions.isEmpty == false {
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
      case .view(.cancelButtonTapped):
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
//    return .send(.internal(.connection(.connect)))
    let data = test2.data(using: .utf8)!
    let response = try! JSONDecoder().decode(ManageActivitiesResponse.self, from: data)
    return handleActions(state: &state, actions: response.actions)
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
      return handleActions(state: &state, actions: response.actions)
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
      "actionId": "0",
      "action": "createActivityTemplate",
      "fields": {
        "identifier": "D4F8A1B2-C3D4-4E5F-8A9B-0C1D2E3F4A5B",
        "name": "Kupno yerby"
      }
    },
    {
      "actionId": "1",
      "action": "createActivityTemplateTask",
      "fields": {
        "activityTemplateIdentifier": "D4F8A1B2-C3D4-4E5F-8A9B-0C1D2E3F4A5B",
        "name": "wypłacić 30 zł"
      }
    },
    {
      "actionId": "2",
      "action": "createDayActivity",
      "fields": {
        "identifier": "7F6E5D4C-3B2A-1C0D-9E8F-0123456789AB",
        "templateIdentifier": "D4F8A1B2-C3D4-4E5F-8A9B-0C1D2E3F4A5B",
        "date": "2026-01-24T00:00:00Z"
      }
    },
    {
      "actionId": "3",
      "action": "createDayActivityTask",
      "fields": {
        "dayActivityId": "7F6E5D4C-3B2A-1C0D-9E8F-0123456789AB",
        "name": "umyć bombiję"
      }
    },
    {
      "actionId": "4",
      "action": "createDayActivityTask",
      "fields": {
        "dayActivityId": "7F6E5D4C-3B2A-1C0D-9E8F-0123456789AB",
        "name": "znaleźć słoik"
      }
    },
    {
      "actionId": "5",
      "action": "createDayActivity",
      "fields": {
        "identifier": "7F6E5D4C-3B2A-1C0D-9E8F-0123456789AA",
        "date": "2026-01-25T00:00:00Z",
        "name": "Biegi"
      }
    },
      {
        "actionId": "6",
        "action": "createDayActivity",
        "fields": {
          "identifier": "D2F6C1A3-7B2E-4D6B-9F8A-1A2B3C4D5E6F",
          "templateIdentifier": "458A0499-9962-46C3-8A04-8ABE8EF20DA4",
          "date": "2026-01-25T00:00:00Z"
        }
      },
      {
        "actionId": "7",
        "action": "createDayActivityTask",
        "fields": {
          "dayActivityId": "D2F6C1A3-7B2E-4D6B-9F8A-1A2B3C4D5E6F",
          "name": "Śniadanie",
          "position": 0
        }
      },
      {
        "actionId": "8",
        "action": "createDayActivityTask",
        "fields": {
          "dayActivityId": "D2F6C1A3-7B2E-4D6B-9F8A-1A2B3C4D5E6F",
          "name": "Obiad",
          "position": 1
        }
      },
      {
        "actionId": "9",
        "action": "createDayActivityTask",
        "fields": {
          "dayActivityId": "D2F6C1A3-7B2E-4D6B-9F8A-1A2B3C4D5E6F",
          "name": "Kolacja",
          "position": 2
        }
      },
      {
        "actionId": "10",
        "action": "createDayActivity",
        "fields": {
          "identifier": "E3A7B2C4-1D3F-4A6B-8C9D-0F1E2D3C4B5A",
          "templateIdentifier": "4934C155-CE7B-4E78-95F1-96C33C056B83",
          "date": "2026-01-25T00:00:00Z"
        }
      },
      {
        "actionId": "11",
        "action": "createDayActivityTask",
        "fields": {
          "dayActivityId": "E3A7B2C4-1D3F-4A6B-8C9D-0F1E2D3C4B5A",
          "name": "Rozgrzewka",
          "position": 0
        }
      },
      {
        "actionId": "12",
        "action": "createDayActivityTask",
        "fields": {
          "dayActivityId": "E3A7B2C4-1D3F-4A6B-8C9D-0F1E2D3C4B5A",
          "name": "Trening główny",
          "position": 1
        }
      },
      {
        "actionId": "13",
        "action": "createDayActivity",
        "fields": {
          "identifier": "F1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D",
          "templateIdentifier": "A0145C46-A537-4C93-B1DD-3DE14F552891",
          "date": "2026-01-25T00:00:00Z"
        }
      },
      {
        "actionId": "14",
        "action": "createDayActivityTask",
        "fields": {
          "dayActivityId": "F1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D",
          "name": "Przeczytaj rozdział",
          "position": 0
        }
      },
    {
      "actionId": "15",
      "action": "createActivityTemplate",
      "fields": {
        "identifier": "F1A2B3C4-D5E6-47F8-9A0B-C1D2E3F4A5B6",
        "name": "Kupno yerby",
        "icon": {
          "value": "🍃"
        }
      }
    },
    {
      "actionId": "16",
      "action": "createDayActivity",
      "fields": {
        "identifier": "0A1B2C3D-4E5F-6789-0ABC-DEF123456789",
        "name": "Kupno yerby",
        "date": "2026-01-24T00:00:00Z",
        "templateIdentifier": "F1A2B3C4-D5E6-47F8-9A0B-C1D2E3F4A5B6"
      }
    },
    {
      "actionId": "17",
      "action": "createDayActivityTask",
      "fields": {
        "dayActivityId": "0A1B2C3D-4E5F-6789-0ABC-DEF123456789",
        "name": "umyć bombiję"
      }
    },
    {
      "actionId": "18",
      "action": "createDayActivityTask",
      "fields": {
        "dayActivityId": "0A1B2C3D-4E5F-6789-0ABC-DEF123456789",
        "name": "znaleźć słoik"
      }
    },
    {
      "actionId": "19",
      "action": "createDayActivity",
      "fields": {
        "identifier": "11111111-1111-1111-1111-111111111111",
        "name": "Praca",
        "date": "2026-01-24T00:00:00Z",
        "icon": {
          "value": "💼"
        }
      }
    },
    {
      "actionId": "20",
      "action": "createDayActivity",
      "fields": {
        "identifier": "22222222-2222-2222-2222-222222222222",
        "name": "Sport",
        "date": "2026-01-24T00:00:00Z",
        "templateIdentifier": "4934C155-CE7B-4E78-95F1-96C33C056B83",
        "icon": {
          "value": "🏃"
        }
      }
    },
    {
      "actionId": "21",
      "action": "createDayActivityTask",
      "fields": {
        "dayActivityId": "11111111-1111-1111-1111-111111111111",
        "name": "Sprawdzić e-maile",
        "position": 0
      }
    },
    {
      "actionId": "22",
      "action": "createDayActivityTask",
      "fields": {
        "dayActivityId": "11111111-1111-1111-1111-111111111111",
        "name": "Skoncentrowana praca nad projektem",
        "position": 1
      }
    },
    {
      "actionId": "23",
      "action": "createDayActivityTask",
      "fields": {
        "dayActivityId": "22222222-2222-2222-2222-222222222222",
        "name": "Rozgrzewka 10 min",
        "position": 0
      }
    },
    {
      "actionId": "24",
      "action": "createDayActivityTask",
      "fields": {
        "dayActivityId": "22222222-2222-2222-2222-222222222222",
        "name": "Trening główny 30 min",
        "position": 1
      }
    }
  ],
  "error": null,
  "_thinking": "Creating the template with its task, making today's activity from it, and adding the two requested tasks to that activity."
}
"""

let test2 = """
{
  "actions": [
    {
          "actionId": "0",
          "action": "createDayActivity",
          "fields": {
            "identifier": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
            "name": "Sport",
            "overview": "Wieczorna sesja sportowa: rozgrzewka, trening główny i rozciąganie.",
            "date": "2026-01-25T00:00:00Z",
            "icon": {
              "value": "🏃"
            }
          }
        },
        {
          "actionId": "1",
          "action": "createDayActivity",
          "fields": {
            "identifier": "9f1b5c2e-3d4a-4b6f-9a2b-1c2d3e4f5a6b",
            "name": "Odpoczynek",
            "overview": "Wieczorny relaks i wyciszenie przed snem.",
            "date": "2026-01-25T00:00:00Z",
            "icon": {
              "value": "😴"
            }
          }
        },
        {
          "actionId": "2",
          "action": "createDayActivityTask",
          "fields": {
            "dayActivityId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
            "name": "Rozgrzewka",
            "overview": "Łagodne rozruszanie stawów i mięśni",
            "position": 0,
            "duration": 10
          }
        },
        {
          "actionId": "3",
          "action": "createDayActivityTask",
          "fields": {
            "dayActivityId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
            "name": "Cardio / trucht",
            "overview": "Krótki bieg lub intensywny marsz",
            "position": 1,
            "duration": 20
          }
        },
        {
          "actionId": "4",
          "action": "createDayActivityTask",
          "fields": {
            "dayActivityId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
            "name": "Ćwiczenia siłowe",
            "overview": "Zestaw ćwiczeń na dużą grupę mięśniową",
            "position": 2,
            "duration": 25
          }
        },
        {
          "actionId": "5",
          "action": "createDayActivityTask",
          "fields": {
            "dayActivityId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
            "name": "Core / brzuch",
            "overview": "Ćwiczenia na mięśnie głębokie tułowia",
            "position": 3,
            "duration": 10
          }
        },
        {
          "actionId": "6",
          "action": "createDayActivityTask",
          "fields": {
            "dayActivityId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
            "name": "Rozciąganie i cool-down",
            "overview": "Łagodne rozciąganie i uspokojenie oddechu",
            "position": 4,
            "duration": 10
          }
        },
        {
          "actionId": "7",
          "action": "createDayActivityTask",
          "fields": {
            "dayActivityId": "9f1b5c2e-3d4a-4b6f-9a2b-1c2d3e4f5a6b",
            "name": "Wyłączenie ekranów",
            "overview": "Odłączenie od urządzeń elektronicznych",
            "position": 0,
            "duration": 30
          }
        },
        {
          "actionId": "8",
          "action": "createDayActivityTask",
          "fields": {
            "dayActivityId": "9f1b5c2e-3d4a-4b6f-9a2b-1c2d3e4f5a6b",
            "name": "Ciepła kąpiel / prysznic",
            "overview": "Relaksująca kąpiel lub prysznic",
            "position": 1,
            "duration": 20
          }
        },
        {
          "actionId": "9",
          "action": "createDayActivityTask",
          "fields": {
            "dayActivityId": "9f1b5c2e-3d4a-4b6f-9a2b-1c2d3e4f5a6b",
            "name": "Lekka lektura",
            "overview": "Czytanie relaksującej książki",
            "position": 2,
            "duration": 20
          }
        },
        {
          "actionId": "10",
          "action": "createDayActivityTask",
          "fields": {
            "dayActivityId": "9f1b5c2e-3d4a-4b6f-9a2b-1c2d3e4f5a6b",
            "name": "Krótka medytacja / oddech",
            "overview": "5–10 minut ćwiczeń oddechowych lub medytacji",
            "position": 3,
            "duration": 10
          }
        },
        {
          "actionId": "11",
          "action": "createDayActivityTask",
          "fields": {
            "dayActivityId": "9f1b5c2e-3d4a-4b6f-9a2b-1c2d3e4f5a6b",
            "name": "Przygotowanie do snu",
            "overview": "Higiena wieczorna i położenie się do snu",
            "position": 4,
            "duration": 10
          }
        }
  ],
  "error": null,
  "_thinking": "Creating the template with its task, making today's activity from it, and adding the two requested tasks to that activity."
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
