import SwiftUI
import Resources
import Utilities
import Models

public struct DaysSelectorView: View {

  // MARK: - Properties

  @Binding private var selectedDay: Day?
  private var newForms: DayView.NewForms?
  private let dayActivities: [DayActivity]
  private let daySummary: DaySummary?
  private let dayViewShowButtonState: DayViewShowButtonState
  private let informationConfiguration: InformationViewConfigurable?
  private let dayActivityAction: (DayActivityActionType) -> Void
  private let showCompletedTapped: () -> Void
  private let hideCompletedTapped: () -> Void

  // MARK: - Initialization

  public init(
    selectedDay: Binding<Day?>,
    newForms: DayView.NewForms? = nil,
    dayActivities: [DayActivity],
    daySummary: DaySummary?,
    dayViewShowButtonState: DayViewShowButtonState,
    informationConfiguration: InformationViewConfigurable?,
    dayActivityAction: @escaping (DayActivityActionType) -> Void,
    showCompletedTapped: @escaping () -> Void,
    hideCompletedTapped: @escaping () -> Void
  ) {
    self._selectedDay = selectedDay
    self.newForms = newForms
    self.dayActivities = dayActivities
    self.daySummary = daySummary
    self.dayViewShowButtonState = dayViewShowButtonState
    self.informationConfiguration = informationConfiguration
    self.dayActivityAction = dayActivityAction
    self.showCompletedTapped = showCompletedTapped
    self.hideCompletedTapped = hideCompletedTapped
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .leading, spacing: .zero) {
      dayActivityList
      timeSummary
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
      newForms: newForms,
      activities: dayActivities,
      completedActivities: day.completedActivities,
      dayViewShowButtonState: dayViewShowButtonState,
      dayActivityAction: dayActivityAction,
      showCompletedTapped: showCompletedTapped,
      hideCompletedTapped: hideCompletedTapped
    )
  }

  @ViewBuilder
  private var timeSummary: some View {
    if let daySummary, daySummary.duration > .zero {
      VStack(spacing: .zero) {
        Divider()
        TimeSummaryView(daySummary: daySummary)
          .padding(.all, 10.0)
      }
    }
  }
}
