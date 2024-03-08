import SwiftUI
import Resources
import Utilities
import Models

public struct DaysSelectorView: View {

  // MARK: - Properties

  @Binding private var selectedDay: Day?
  private let dayActivities: [DayActivity]
  private let daysSelectorStyle: DaysSelectorStyle
  private let daySummary: DaySummary?
  private let dayViewShowButtonState: DayViewShowButtonState
  private let dayActivityTapped: (DayActivity) -> Void
  private let dayActivityEditTapped: (DayActivity) -> Void
  private let removeDayActivityTapped: (DayActivity) -> Void
  private let showCompletedTapped: () -> Void
  private let hideCompletedTapped: () -> Void

  // MARK: - Initialization

  public init(
    selectedDay: Binding<Day?>,
    dayActivities: [DayActivity],
    daysSelectorStyle: DaysSelectorStyle,
    daySummary: DaySummary?,
    dayViewShowButtonState: DayViewShowButtonState,
    dayActivityTapped: @escaping (DayActivity) -> Void,
    dayActivityEditTapped: @escaping (DayActivity) -> Void,
    removeDayActivityTapped: @escaping (DayActivity) -> Void,
    showCompletedTapped: @escaping () -> Void,
    hideCompletedTapped: @escaping () -> Void
  ) {
    self._selectedDay = selectedDay
    self.dayActivities = dayActivities
    self.daysSelectorStyle = daysSelectorStyle
    self.daySummary = daySummary
    self.dayViewShowButtonState = dayViewShowButtonState
    self.dayActivityTapped = dayActivityTapped
    self.dayActivityEditTapped = dayActivityEditTapped
    self.removeDayActivityTapped = removeDayActivityTapped
    self.showCompletedTapped = showCompletedTapped
    self.hideCompletedTapped = hideCompletedTapped
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .leading, spacing: .zero) {
      daysSelector
      dayActivityList
      timeSummary
    }
  }

  @ViewBuilder
  private var daysSelector: some View {
    if case .multi(let days) = daysSelectorStyle {
      VStack(spacing: 10.0) {
        ScrollView(.horizontal) {
          HStack(spacing: 10.0) {
            ForEach(days) { day in
              dayView(day)
                .onTapGesture {
                  selectedDay = day
                }
            }
          }
          .padding(.horizontal, 10.0)
        }
        Divider()
      }
      .padding(.top, 10.0)
    }
  }

  private func dayView(_ day: Day) -> some View {
    Text(weekday(day))
      .font(font(day))
      .foregroundStyle(foregroundColor(day))
  }

  private func weekday(_ day: Day) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE"
    return dateFormatter.string(from: day.date)
  }

  private func foregroundColor(_ day: Day) -> Color {
    day == selectedDay
    ? Colors.deepSpaceBlue.swiftUIColor
    : Colors.slateHaze.swiftUIColor
  }

  private func font(_ day: Day) -> SwiftUI.Font {
    day == selectedDay
    ? .system(size: 12.0, weight: .semibold)
    : .system(size: 12.0, weight: .regular)
  }

  @ViewBuilder
  private var timeSummary: some View {
    if let daySummary {
      TimeSummaryView(daySummary: daySummary)
        .padding(.all, 10.0)
    }
  }

  @ViewBuilder
  private var dayActivityList: some View {
    if let selectedDay {
      dayViewList(selectedDay)
    }
  }

  @ViewBuilder
  private func dayViewList(_ day: Day) -> some View {
    if day.activities.isEmpty {
      noActivitiesInformation(isPastDay: day.isOlderThenToday ?? false)
    } else {
      listDayView(day)
    }
  }

  @ViewBuilder
  private func noActivitiesInformation(isPastDay: Bool) -> some View {
    EmptyView()
    #warning("Fix noActivitiesInformation")
//    let configuration: EmptyDayConfiguration = isPastDay ? .pastDay : .todayOrFuture
//    InformationView(configuration: configuration)
  }

  private func listDayView(_ day: Day) -> some View {
    DayView(
      isPastDay: day.isOlderThenToday ?? false,
      activities: dayActivities,
      completedActivities: day.completedActivities,
      dayViewShowButtonState: dayViewShowButtonState,
      activityTapped: dayActivityTapped,
      editTapped: dayActivityEditTapped,
      removeTapped: removeDayActivityTapped,
      showCompletedTapped: showCompletedTapped,
      hideCompletedTapped: hideCompletedTapped
    )
  }
}
