import ComposableArchitecture
import Models
import Foundation

#warning("Helper to remove")
extension Date {
  static func date(from string: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
    return dateFormatter.date(from: string) ?? Date()
  }
}

public struct DashboardFeature: Reducer {

  // MARK: - State & Action

  public struct State: Equatable {

    let options = DashboardOption.allCases
    var selectedOption = DashboardOption.toDo
    let userName: String

    var activities = [
      Activity(
        id: UUID(),
        name: "Siłownia",
        emoji: "🏋️‍♀️",
        category: ActivityCategory(
          id: UUID(1),
          name: "Sport",
          emoji: "⚽️",
          color: .blue
        ),
        state: .completed(
          startDate: Date.date(from: "10.10.2021 07:31"),
          endDate: Date.date(from: "10.10.2021 08:55")
        )
      ),
      Activity(
        id: UUID(),
        name: "Joga",
        emoji: "🧘",
        category: ActivityCategory(
          id: UUID(1),
          name: "Sport",
          emoji: "⚽️",
          color: .blue
        ),
        state: .completed(
          startDate: Date.date(from: "10.10.2021 17:34"),
          endDate: Date.date(from: "10.10.2021 19:00")
        )
      ),
      Activity(
        id: UUID(),
        name: "Czytanie",
        emoji: "📚",
        category: ActivityCategory(
          id: UUID(2),
          name: "Rozwój",
          emoji: "📈",
          color: .orange
        ),
        state: .toDo
      ),
      Activity(
        id: UUID(),
        name: "Praca",
        emoji: "💼",
        category: ActivityCategory(
          id: UUID(3),
          name: "Work",
          emoji: "💼",
          color: .red
        ),
        state: .toDo
      ),
      Activity(
        id: UUID(),
        name: "Sauna",
        emoji: "🧖",
        category: ActivityCategory(
          id: UUID(4),
          name: "Odpoczynek",
          emoji: "🎈",
          color: .yellow
        ),
        state: .completed(
          startDate: Date.date(from: "10.10.2021 19:02"),
          endDate: Date.date(from: "10.10.2021 21:03")
        )
      ),
      Activity(
        id: UUID(),
        name: "Drzemka",
        emoji: "🛏️",
        category: ActivityCategory(
          id: UUID(4),
          name: "Odpoczynek",
          emoji: "🎈",
          color: .yellow
        ),
        state: .toDo
      )
    ]

    public init(userName: String = NSUserName()) {
      self.userName = userName
    }
  }

  public enum Action: Equatable {
    case startGameTapped
    case optionTapped(DashboardOption)
    case delegate(Delegate)
  }

  public enum Delegate: Equatable {
    case startGameTapped
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .startGameTapped:
        return .run { send in
          await send(.delegate(.startGameTapped))
        }
      case .optionTapped(let option):
        state.selectedOption = option
        return .none
      case .delegate:
        return .none
      }
    }
  }

  // MARK: - Initialization

  public init() { }
}
