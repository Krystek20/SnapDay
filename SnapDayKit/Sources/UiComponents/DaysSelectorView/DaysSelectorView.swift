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
  private let informationConfiguration: InformationViewConfigurable?
  private let dayViewOption: DayViewOption
  private let showCompletedTapped: () -> Void
  private let hideCompletedTapped: () -> Void

  // MARK: - Initialization

  public init(
    selectedDay: Binding<Day?>,
    dayActivities: [DayActivity],
    daysSelectorStyle: DaysSelectorStyle,
    daySummary: DaySummary?,
    dayViewShowButtonState: DayViewShowButtonState,
    informationConfiguration: InformationViewConfigurable?,
    dayViewOption: DayViewOption,
    showCompletedTapped: @escaping () -> Void,
    hideCompletedTapped: @escaping () -> Void
  ) {
    self._selectedDay = selectedDay
    self.dayActivities = dayActivities
    self.daysSelectorStyle = daysSelectorStyle
    self.daySummary = daySummary
    self.dayViewShowButtonState = dayViewShowButtonState
    self.informationConfiguration = informationConfiguration
    self.dayViewOption = dayViewOption
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
      dayViewOption: dayViewOption,
      showCompletedTapped: showCompletedTapped,
      hideCompletedTapped: hideCompletedTapped
    )
  }
}
