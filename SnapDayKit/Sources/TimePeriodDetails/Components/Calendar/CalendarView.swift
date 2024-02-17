import SwiftUI
import Models
import Resources
import UiComponents

struct CalendarView: View {

  // MARK: - Properties

  @Binding private var selectedDay: Day?
  private let calendarItems: [CalendarItemType]
  private let dayActivityTapped: (DayActivity) -> Void
  private let dayActivityEditTapped: (DayActivity, Day) -> Void
  private let removeDayActivityTapped: (DayActivity, Day) -> Void
  private let columns = Array(repeating: GridItem(), count: 7)

  // MARK: - Initialization

  init(
    selectedDay: Binding<Day?>,
    calendarItems: [CalendarItemType],
    dayActivityTapped: @escaping (DayActivity) -> Void,
    dayActivityEditTapped: @escaping (DayActivity, Day) -> Void,
    removeDayActivityTapped: @escaping (DayActivity, Day) -> Void
  ) {
    self._selectedDay = selectedDay
    self.calendarItems = calendarItems
    self.dayActivityTapped = dayActivityTapped
    self.dayActivityEditTapped = dayActivityEditTapped
    self.removeDayActivityTapped = removeDayActivityTapped
  }

  var body: some View {
    LazyVStack(alignment: .leading, spacing: 20.0) {
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
      dayActivityList
    }
  }

  @ViewBuilder
  private func itemView(_ calendarItem: CalendarItemType) -> some View {
    switch calendarItem {
    case .dayOfWeek(let title):
      Text(title)
        .font(Fonts.Quicksand.bold.swiftUIFont(size: 14.0))
        .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
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
    ? Colors.deepSpaceBlue.swiftUIColor
    : Colors.slateHaze.swiftUIColor
  }

  private func font(_ day: Day) -> SwiftUI.Font {
    day == selectedDay
    ? Fonts.Quicksand.bold.swiftUIFont(size: 14.0)
    : Fonts.Quicksand.medium.swiftUIFont(size: 12.0)
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
    let configuration: EmptyDayConfiguration = isPastDay ? .pastDay : .todayOrFuture
    InformationView(configuration: configuration)
  }

  private func listDayView(_ day: Day) -> some View {
    DayView(
      isPastDay: day.isOlderThenToday ?? false,
      activities: day.activities.sortedByName,
      activityListOption: .extended,
      activityTapped: { dayActivity in
        dayActivityTapped(dayActivity)
      },
      editTapped: { dayActivity in
        dayActivityEditTapped(dayActivity, day)
      },
      removeTapped: { dayActivity in
        removeDayActivityTapped(dayActivity, day)
      }
    )
  }
}
