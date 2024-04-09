import SwiftUI
import Models
import Resources

public struct CalendarView: View {

  // MARK: - Properties

  @Binding private var selectedDay: Day?
  private let dayActivities: [DayActivity]
  private let calendarItems: [CalendarItemType]
  private let daySummary: DaySummary?
  private let dayViewShowButtonState: DayViewShowButtonState
  private let informationConfiguration: InformationViewConfigurable?
  private let dayActivityTapped: (DayActivity) -> Void
  private let dayActivityEditTapped: (DayActivity) -> Void
  private let removeDayActivityTapped: (DayActivity) -> Void
  private let dayActivityTaskTapped: (DayActivity, DayActivityTask) -> Void
  private let dayActivityEditTaskTapped: (DayActivity, DayActivityTask) -> Void
  private let removeDayActivityTaskTapped: (DayActivity, DayActivityTask) -> Void
  private let showCompletedTapped: () -> Void
  private let hideCompletedTapped: () -> Void
  private let columns = Array(repeating: GridItem(), count: 7)

  // MARK: - Initialization

  public init(
    selectedDay: Binding<Day?>,
    dayActivities: [DayActivity],
    calendarItems: [CalendarItemType],
    daySummary: DaySummary?,
    dayViewShowButtonState: DayViewShowButtonState,
    informationConfiguration: InformationViewConfigurable?,
    dayActivityTapped: @escaping (DayActivity) -> Void,
    dayActivityEditTapped: @escaping (DayActivity) -> Void,
    removeDayActivityTapped: @escaping (DayActivity) -> Void,
    dayActivityTaskTapped: @escaping (DayActivity, DayActivityTask) -> Void,
    dayActivityEditTaskTapped: @escaping (DayActivity, DayActivityTask) -> Void,
    removeDayActivityTaskTapped: @escaping (DayActivity, DayActivityTask) -> Void,
    showCompletedTapped: @escaping () -> Void,
    hideCompletedTapped: @escaping () -> Void
  ) {
    self._selectedDay = selectedDay
    self.dayActivities = dayActivities
    self.calendarItems = calendarItems
    self.daySummary = daySummary
    self.dayViewShowButtonState = dayViewShowButtonState
    self.informationConfiguration = informationConfiguration
    self.dayActivityTapped = dayActivityTapped
    self.dayActivityEditTapped = dayActivityEditTapped
    self.removeDayActivityTapped = removeDayActivityTapped
    self.dayActivityTaskTapped = dayActivityTaskTapped
    self.dayActivityEditTaskTapped = dayActivityEditTaskTapped
    self.removeDayActivityTaskTapped = removeDayActivityTaskTapped
    self.showCompletedTapped = showCompletedTapped
    self.hideCompletedTapped = hideCompletedTapped
  }

  public var body: some View {
    LazyVStack(alignment: .leading, spacing: .zero) {
      LazyVGrid(columns: columns, spacing: 20) {
        ForEach(calendarItems) { item in
          itemView(item)
            .frame(height: 20.0)
            .onTapGesture {
              guard case .day(let day) = item else { return }
              selectedDay = day
            }
        }
      }
      .padding(.vertical, 10.0)
      Divider()
      dayActivityList
      timeSummary
    }
  }

  @ViewBuilder
  private func itemView(_ calendarItem: CalendarItemType) -> some View {
    switch calendarItem {
    case .dayOfWeek(let title):
      Text(title)
        .font(.system(size: 12.0, weight: .semibold))
        .foregroundStyle(Color.standardText)
    case .day(let day):
      Text(dayNumber(day))
        .font(font(day))
        .foregroundStyle(foregroundColor(day))
    case .empty:
      Color.clear
    }
  }

  private func dayNumber(_ day: Day) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd"
    return dateFormatter.string(from: day.date)
  }

  private func foregroundColor(_ day: Day) -> Color {
    day == selectedDay
    ? .standardText
    : .sectionText
  }

  private func font(_ day: Day) -> SwiftUI.Font {
    day == selectedDay
    ? .system(size: 12.0, weight: .semibold)
    : .system(size: 12.0, weight: .regular)
  }

  @ViewBuilder
  private var timeSummary: some View {
    if let daySummary, daySummary.duration > .zero {
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
    if let informationConfiguration {
      InformationView(configuration: informationConfiguration)
    } else {
      listDayView(day)
    }
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
      activityTaskTapped: dayActivityTaskTapped,
      editTaskTapped: dayActivityEditTaskTapped,
      removeTaskTapped: removeDayActivityTaskTapped,
      showCompletedTapped: showCompletedTapped,
      hideCompletedTapped: hideCompletedTapped
    )
  }
}
