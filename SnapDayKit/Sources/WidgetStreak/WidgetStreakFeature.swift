import Foundation
import ComposableArchitecture
import Utilities
import Models
import Resources

@Reducer
public struct WidgetStreakFeature: TodayProvidable {

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    public enum ContentType {
      case start(name: String)
      case streak(name: String, current: String, nextTitle: String, next: String, percent: Double)
    }

    private var activity: Activity?
    private var streak: Streak?

    var image: Images {
      guard let streak else { return .strike0 }
      return switch streak.current {
      case .zero:
        .strike0
      case 1...3:
        .strike1_3
      case 4...7:
        .strike4_7
      case 8...14:
        .strike8_14
      case 15...30:
        .strike15_30
      case 31...:
        .strike31
      default:
        .strike0
      }
    }

    var contentType: ContentType {
      guard let activity,
            let streak else {
        return .start(name: String(localized: "Select activity", bundle: .module))
      }
      switch streak.current {
      case .zero:
        return .start(name: activity.name)
      case 1...:
        return .streak(
          name: activity.name,
          current: String(streak.current),
          nextTitle: streak.next == streak.logest
          ? String(localized: "Best", bundle: .module)
          : String(localized: "Next", bundle: .module),
          next: String(streak.next),
          percent: Double(streak.current) / Double(streak.next)
        )
      default:
        return .start(name: activity.name)
      }
    }

    public init(
      activity: Activity?,
      streak: Streak?
    ) {
      self.activity = activity
      self.streak = streak
    }
  }

  public enum Action: Equatable { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    EmptyReducer()
  }

  // MARK: - Initialization

  public init() { }
}
