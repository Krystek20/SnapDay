import SwiftUI
import Resources
import Utilities
import UiComponents
import Models

struct DaysSelectorView: View {

  // MARK: - Properties

  @Binding private var selectedDay: Day?
  private let days: [Day]
  private let dayActivityTapped: (DayActivity) -> Void
  private let dayActivityEditTapped: (DayActivity, Day) -> Void
  private let removeDayActivityTapped: (DayActivity, Day) -> Void

  // MARK: - Initialization

  init(
    selectedDay: Binding<Day?>,
    days: [Day],
    dayActivityTapped: @escaping (DayActivity) -> Void,
    dayActivityEditTapped: @escaping (DayActivity, Day) -> Void,
    removeDayActivityTapped: @escaping (DayActivity, Day) -> Void
  ) {
    self._selectedDay = selectedDay
    self.days = days
    self.dayActivityTapped = dayActivityTapped
    self.dayActivityEditTapped = dayActivityEditTapped
    self.removeDayActivityTapped = removeDayActivityTapped
  }

  // MARK: - Views

  var body: some View {
    VStack(alignment: .leading, spacing: 20.0) {
      ScrollView(.horizontal) {
        HStack(spacing: 10.0) {
          ForEach(days) { day in
            dayView(day)
              .onTapGesture {
                selectedDay = day
              }
          }
        }
      }
      dayActivityList
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
