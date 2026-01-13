import SwiftUI
import Resources
import Utilities
import Models

public struct DaysSelectorView: View {

  // MARK: - Properties

  @Binding private var selectedDay: Day?
  @Binding private var items: [ListItem]
  private let daySummary: DaySummary?
  private let informationConfiguration: InformationViewConfigurable?
  private let dayActivityAction: (ListItemAction) -> Void

  // MARK: - Initialization

  public init(
    selectedDay: Binding<Day?>,
    items: Binding<[ListItem]>,
    daySummary: DaySummary?,
    informationConfiguration: InformationViewConfigurable?,
    dayActivityAction: @escaping (ListItemAction) -> Void
  ) {
    self._selectedDay = selectedDay
    self._items = items
    self.daySummary = daySummary
    self.informationConfiguration = informationConfiguration
    self.dayActivityAction = dayActivityAction
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .leading, spacing: .zero) {
      informationView
      dayActivityList
      timeSummary
    }
  }

  @ViewBuilder
  private var dayActivityList: some View {
    if let selectedDay {
      listView(selectedDay)
    }
  }

  @ViewBuilder
  private var informationView: some View {
    if let informationConfiguration {
      InformationView(configuration: informationConfiguration)
    }
  }

  private func listView(_ day: Day) -> some View {
    ListView(
      items: $items,
      completedActivities: day.completedActivities,
      action: dayActivityAction
    )
  }

  @ViewBuilder
  private var timeSummary: some View {
    if let daySummary, daySummary.duration > .zero {
      TimeSummaryView(daySummary: daySummary)
        .padding(.all, 10.0)
    }
  }
}
