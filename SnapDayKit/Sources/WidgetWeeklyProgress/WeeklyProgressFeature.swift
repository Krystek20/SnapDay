import Foundation
import ComposableArchitecture
import Utilities
import Models
import Resources

struct ProgressItem: Equatable, Identifiable {

  enum State: Equatable {
    case completionPercent(Double)
    case nothingPlanned

    var icon: String {
      switch self {
      case .completionPercent(let completionPercent):
        switch completionPercent {
        case ...0: "🌑"
        case 0..<0.34: "🌒"
        case 0.34..<0.67: "🌓"
        case 0.67..<1.0: "🌔"
        case 1.0...: "🌕"
        default: "⚪️"
        }
      case .nothingPlanned: "⚪️"
      }
    }
  }

  let id: TimeInterval
  let label: String
  let state: State
}

@Reducer
public struct WeeklyProgressFeature: TodayProvidable {

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    var progressItems: [ProgressItem] {
      days.map { day in
        let state: ProgressItem.State = day.plannedCount == .zero
        ? .nothingPlanned
        : .completionPercent(day.completedValue)
        return ProgressItem(
          id: day.date.timeIntervalSince1970,
          label: formatter.string(from: day.date),
          state: state
        )
      }
    }

    var doneActivitiesCount: Int {
      days.reduce(into: 0) { result, day in
        guard day.date <= today, day.plannedCount > 0 else { return }
        result += day.completedCount
      }
    }

    var doneDaysCount: Int {
      days.reduce(into: 0) { result, day in
        guard day.date <= today, day.plannedCount > 0 else { return }
        if day.completedCount == day.plannedCount {
          result += 1
        }
      }
    }

    private let formatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.locale = .preferred
      formatter.dateFormat = "E"
      return formatter
    }()

    let days: [Day]
    let showTotalActivities: Bool
    let showTotalSpentTime: Bool

    public init(
      days: [Day],
      showTotalActivities: Bool,
      showTotalSpentTime: Bool
    ) {
      self.days = days
      self.showTotalActivities = showTotalActivities
      self.showTotalSpentTime = showTotalSpentTime
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
