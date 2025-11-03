import Foundation
import ComposableArchitecture
import Common
import Repositories

@Reducer
public struct DictationFeature {

  // MARK: - Dependecies

  @Dependency(\.dismiss) private var dismiss
  @Dependency(\.webSocket) private var webSocket

  private let speechAnalyzer = SpeechAnalyzer()

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {
    
    var transcribedText = ""
    var isListening = false

    @ObservationStateIgnored
    var connection: WebSocketConnection?

    @ObservationStateIgnored
    var isConnected = false

    public init() { }
  }

  public enum Action: BindableAction, FeatureAction, Equatable {
    public enum ViewAction: Equatable {
      case onAppear
      case saveButtonTapped
      case cancelButtonTapped
    }
    public enum InternalAction: Equatable {
      case start
      case setText(String)
      case connection(ConnectionAction)
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
      case .view(.onAppear):
        .send(.internal(.start))
      case .view(.saveButtonTapped):
        .none
      case .view(.cancelButtonTapped):
        .run { _ in
          await dismiss()
        }
      case .internal(.start):
        start(state: &state)
      case .internal(.setText(let text)):
        setText(state: &state, text: text)
      case .internal(.connection(let action)):
        handleConnectionAction(state: &state, action: action)
      case .delegate(.dataSelected):
        .none
      case .delegate:
        .none
      case .binding:
        .none
      }
    }
  }

  private func start(state: inout State) -> Effect<Action> {
    state.isListening = true
    return .run { send in
      let text = try await speechAnalyzer.start()
      await send(.internal(.setText(text)))
    }
  }

  private func setText(state: inout State, text: String) -> Effect<Action> {
    state.transcribedText = text
    state.isListening = false
    return .none
  }

  private func handleConnectionAction(state: inout State, action: Action.ConnectionAction) -> Effect<Action> {
    switch action {
    case .connect:
      let path = "wss://relieved-manatee-wildly.ngrok-free.app/api/v1/manage-activities"
      guard let url = URL(string: path) else { return .none }
      let (connection, stream) = webSocket.connect(url)
      return .merge(
        .send(.internal(.connection(.connected(connection)))),
//        setGoalDefinition(state: &state, suggestionsOn: true),
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
//          let response = try decoder.decode(GoalPlanningEvent.self, from: data)
//          return .send(.internal(.handleGoalPlanningEvent(response)))
          return .none
        } catch {
          print(error)
          return .none
        }
      case .data(let data):
        do {
//          let response = try decoder.decode(GoalPlanningEvent.self, from: data)
//          return .send(.internal(.handleGoalPlanningEvent(response)))
          return .none
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
}

struct UserContext: Encodable, Equatable {
  let now: Date
}

public enum ManageActivitiesMessageType: Encodable, Equatable {
  case userRequest(String)
}

struct ManageActivitiesRequest: Encodable, Equatable {
  let message: ManageActivitiesMessageType
  let userContext: UserContext
}
