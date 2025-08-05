import Foundation
import ComposableArchitecture
import Utilities
import Models

import struct UiComponents.ListItem

@Reducer
public struct WidgetActivityListFeature: TodayProvidable {

  public enum ContentType: Equatable {
    case list([ListItem])
    case success
    case empty
  }

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable, TodayProvidable {

    var title: String {
      let formatter = DateFormatter()
      formatter.locale = .preferred
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
      allItems.count <= maxPerPage * (ListConfiguration.currentPage + 1)
    }

    var contentType: ContentType {
      guard let selectedDay, !selectedDay.activities.isEmpty else { return .empty }
      return selectedDay.activities.allSatisfy(\.isDone)
      ? .success
      : .list(items)
    }

    private var items: [ListItem] {
      let items = allItems
      let lowerBounds = maxPerPage * ListConfiguration.currentPage
      let upperBounds = min(items.count, maxPerPage * (ListConfiguration.currentPage + 1))
      return Array(items[lowerBounds..<upperBounds])
    }

    var completedActivities: CompletedActivities? {
      switch contentType {
      case .list, .success:
        selectedDay?.completedActivities
      case .empty:
        nil
      }
    }

    private var allItems: [ListItem] {
      @Dependency(\.utcCalendar) var calendar
      guard let selectedDay else { return [] }
      let activities = selectedDay
        .activities
        .sorted(calendar: calendar)

      return ListItemsBuilder(
        activities: activities,
        hideCompleted: hideCompleted,
        icons: icons
      ).build()
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
