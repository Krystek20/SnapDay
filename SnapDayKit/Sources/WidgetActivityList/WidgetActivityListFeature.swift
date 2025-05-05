import Foundation
import ComposableArchitecture
import Utilities
import Models
import struct UiComponents.DayActivityItem

@Reducer
public struct WidgetActivityListFeature: TodayProvidable {

  public enum ContentType: Equatable {
    case list([DayActivityItem])
    case success
    case empty
  }

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    var title: String {
      let formatter = DateFormatter()
      formatter.dateFormat = "EEEE, d MMM yyyy"
      if let firstPreferredLanguage = Locale.preferredLanguages.first {
        formatter.locale = Locale(identifier: firstPreferredLanguage)
      }
      return formatter.string(from: today)
    }

    var isButtonSectionShown: Bool {
      guard let selectedDay else { return false }
      return !selectedDay.activities.allSatisfy(\.isDone) && !selectedDay.activities.isEmpty
    }

    var isUpButtonDisabled: Bool {
      ListConfiguration.currentPage == .zero
    }

    var isDownButtonDisabled: Bool {
      allDayActivityItems.count <= maxPerPage * (ListConfiguration.currentPage + 1)
    }

    var contentType: ContentType {
      guard let selectedDay, !selectedDay.activities.isEmpty else { return .empty }
      return selectedDay.activities.allSatisfy(\.isDone)
      ? .success
      : .list(dayActivityItems)
    }

    private var dayActivityItems: [DayActivityItem] {
      let dayActivityItems = allDayActivityItems
      let lowerBounds = maxPerPage * ListConfiguration.currentPage
      let upperBounds = min(dayActivityItems.count, maxPerPage * (ListConfiguration.currentPage + 1))
      return Array(dayActivityItems[lowerBounds..<upperBounds])
    }

    var completedActivities: CompletedActivities? {
      switch contentType {
      case .list, .success:
        selectedDay?.completedActivities
      case .empty:
        nil
      }
    }

    private var allDayActivityItems: [DayActivityItem] {
      @Dependency(\.utcCalendar) var calendar
      guard let selectedDay else { return [] }
      return selectedDay
        .activities
        .sorted(calendar: calendar)
        .reduce(into: [DayActivityItem](), { result, dayActivity in
          let ignoreActivity = hideCompleted && dayActivity.isDone
          if !ignoreActivity {
            var iconData: Data?
            if let iconId = dayActivity.iconId,
               let icon = icons.first(where: { $0.id == iconId }) {
              iconData = icon.data
            }
            result.append(
              DayActivityItem(
                activityType: dayActivity,
                iconRules: .data(iconData)
              )
            )
          }

          result.append(
            contentsOf: dayActivity.dayActivityTasks.sorted(calendar: calendar).compactMap { dayActivityTask in
              let ignoreTask = hideCompleted && dayActivityTask.isDone
              guard !ignoreActivity && !ignoreTask else {
                return nil
              }
              return DayActivityItem(
                activityType: dayActivityTask,
                iconRules: .none,
                parentId: dayActivity.id
              )
            }
          )
        })
    }

    private var maxPerPage = 6
    private var selectedDay: Day?
    private let hideCompleted: Bool
    private let icons: [Icon]

    public init(
      day: Day?,
      icons: [Icon],
      hideCompleted: Bool
    ) {
      self.selectedDay = day
      self.icons = icons
      self.hideCompleted = hideCompleted
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
