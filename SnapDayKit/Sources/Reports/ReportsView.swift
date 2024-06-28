import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import Utilities
import SelectableList

@MainActor
public struct ReportsView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<ReportsFeature>
  private let columns = Array(repeating: GridItem(), count: 7)

  // MARK: - Initialization

  public init(store: StoreOf<ReportsFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          content
            .padding(.horizontal, 15.0)
            .padding(.top, store.isSwitcherDismissed ? 15.0: 65.0)
        }
        .maxWidth()
        .scrollIndicators(.hidden)

        if store.isSwitcherDismissed {
          Divider()
        } else {
          Switcher(
            title: store.switcherTitle,
            leftArrowAction: {
              store.send(.view(.decreaseButtonTapped))
            },
            rightArrowAction: {
              store.send(.view(.increaseButtonTapped))
            }
          )
        }
      }
      .activityBackground
      .task {
        store.send(.view(.appeared))
      }
      .navigationTitle(String(localized: "Reports", bundle: .module))
      .sheet(item: $store.scope(state: \.selectableList, action: \.selectableList)) { store in
        NavigationStack {
          SelectableListView(store: store)
            .navigationBarTitleDisplayMode(.large)
        }
        .presentationDetents([.medium])
      }
    }
  }

  private var content: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 10.0) {
        picker
        customDatePickers
        monthsView
        progress
        filtersSection
        summarySection
        activitiesByTag
      }
      .maxWidth()
    }
  }

  @MainActor
  private var picker: some View {
    WithPerceptionTracking {
      Picker(
        selection: $store.selectedFilterPeriod,
        content: {
          ForEach(store.dateFilters) { period in
            Text(period.name).tag(period)
          }
        },
        label: { EmptyView() }
      )
      .pickerStyle(.segmented)
    }
  }

  @ViewBuilder
  private var customDatePickers: some View {
    WithPerceptionTracking {
      if store.showCustomDate {
        VStack {
          DatePicker(
            selection: $store.startDate,
            in: ...store.endDate,
            displayedComponents: [.date],
            label: {
              Text("Start", bundle: .module)
                .formTitleTextStyle
            }
          )
          DatePicker(
            selection: $store.endDate,
            in: store.startDate...,
            displayedComponents: [.date],
            label: {
              Text("End", bundle: .module)
                .formTitleTextStyle
            }
          )
        }
        .formBackgroundModifier()
      }
    }
  }

  @ViewBuilder
  private var progress: some View {
    WithPerceptionTracking {
      if let linearChartValues = store.linearChartValues {
        SectionView(
          name: String(localized: "Progress", bundle: .module),
          rightContent: { EmptyView() },
          content: {
            LinearChartView(
              points: linearChartValues.points,
              expectedPoints: linearChartValues.expectedPoints,
              currentPoint: linearChartValues.currentPoint
            )
            .frame(height: 200.0)
            .padding(.vertical, 15.0)
            .formBackgroundModifier()
          }
        )
      }
    }
  }

  private var filtersSection: some View {
    SectionView(
      name: String(localized: "Filters", bundle: .module),
      rightContent: { EmptyView() },
      content: {
        VStack(spacing: 10.0) {
          filterByTagsView
          filterByActivitiesView
          filterByLabelsView
        }
        .formBackgroundModifier()
      }
    )
  }

  @ViewBuilder
  private var filterByTagsView: some View {
    WithPerceptionTracking {
      if let selectedTag = store.selectedTag {
        HStack(spacing: 10.0) {
          Text("Tag", bundle: .module)
            .formTitleTextStyle
          Spacer()
          MarkerView(marker: selectedTag)
            .onTapGesture {
              store.send(.view(.tagTapped))
            }
        }
      }
    }
  }

  @ViewBuilder
  private var filterByActivitiesView: some View {
    WithPerceptionTracking {
      if !store.activities.isEmpty {
        HStack(spacing: 10.0) {
          Text("Activity", bundle: .module)
            .formTitleTextStyle
          Spacer()
          if let selectedActivity = store.selectedActivity {
            ActivityView(activity: selectedActivity)
              .onTapGesture {
                store.send(.view(.selectActivityButtonTapped))
              }
          } else {
            Button(String(localized: "Select", bundle: .module)) {
              store.send(.view(.selectActivityButtonTapped))
            }
            .foregroundStyle(Color.actionBlue)
            .font(.system(size: 12.0, weight: .bold))
          }
        }
      }
    }
  }
  
  @ViewBuilder
  private var filterByLabelsView: some View {
    WithPerceptionTracking {
      if store.showLabel {
        HStack(spacing: 10.0) {
          Text("Label", bundle: .module)
            .formTitleTextStyle
          Spacer()
          if let selectedLabel = store.selectedLabel {
            MarkerView(marker: selectedLabel)
              .onTapGesture {
                store.send(.view(.labelTapped))
              }
          } else {
            Button(String(localized: "Select", bundle: .module)) {
              store.send(.view(.labelTapped))
            }
            .foregroundStyle(Color.actionBlue)
            .font(.system(size: 12.0, weight: .bold))
          }
        }
      }
    }
  }

  @ViewBuilder
  private var summarySection: some View {
    WithPerceptionTracking {
      if store.reportDays.count > 1 {
        SectionView(
          name: String(localized: "Summary", bundle: .module),
          rightContent: { },
          content: {
            summaryView
          }
        )
      }
    }
  }

  private var summaryView: some View {
    LazyVStack(alignment: .leading, spacing: 10.0) {
      reportDaysView
      statisticsView
    }
    .maxWidth()
    .formBackgroundModifier()
  }

  private var statisticsView: some View {
    WithPerceptionTracking {
      VStack(spacing: 10.0) {
        if store.summary.doneCount > .zero {
          HStack(spacing: 5.0) {
            Text("Done Count", bundle: .module)
              .formTitleTextStyle
            Spacer()
            Text("\(store.summary.doneCount)")
              .font(.system(size: 12.0, weight: .bold))
              .foregroundStyle(Color.standardText)
          }
        }
        if store.summary.notDoneCount > .zero {
          HStack(spacing: 5.0) {
            Text("Not Done Count", bundle: .module)
              .formTitleTextStyle
            Spacer()
            Text("\(store.summary.notDoneCount)")
              .font(.system(size: 12.0, weight: .bold))
              .foregroundStyle(Color.standardText)
          }
        }
        if store.summary.duration > .zero {
          HStack(spacing: 5.0) {
            Text("Total Time", bundle: .module)
              .formTitleTextStyle
            Spacer()
            Text(TimeProvider.duration(from: store.summary.duration, bundle: .module) ?? "")
              .font(.system(size: 12.0, weight: .bold))
              .foregroundStyle(Color.standardText)
          }
        }
      }
    }
  }

  private var reportDaysView: some View {
    WithPerceptionTracking {
      LazyVGrid(columns: columns, spacing: 10) {
        ForEach(store.reportDays) { item in
          VStack(spacing: 2.0) {
            if let title = item.title {
              Text(title)
                .font(.system(size: 12.0, weight: .semibold))
                .foregroundStyle(Color.standardText)
            }
            reportDayActivityView(item)
              .frame(height: 30.0)
              .clipShape(RoundedRectangle(cornerRadius: 15.0))
          }
        }
      }
    }
  }

  @ViewBuilder
  private func reportDayActivityView(_ reportDay: ReportDay) -> some View {
    WithPerceptionTracking {
      switch reportDay.dayActivity {
      case .tag(let state):
        if let tag = store.selectedTag {
          switch state {
          case .done:
            tag.rgbColor.color
          case .notDone, .planned:
            tag.rgbColor.color.opacity(0.2)
          case .notPlanned:
            Color.clear
          }
        }
      case .activity(let state):
        if let activity = store.selectedActivity {
          switch state {
          case .done:
            ActivityImageView(data: activity.icon?.data, size: 30.0, cornerRadius: 15.0)
          case .notDone, .planned:
            ActivityImageView(data: activity.icon?.data, size: 30.0, cornerRadius: 15.0)
              .opacity(0.2)
          case .notPlanned:
            Color.clear
          }
        }
      case .empty:
        Color.clear
      }
    }
  }

  @MainActor
  @ViewBuilder
  private var activitiesByTag: some View {
    WithPerceptionTracking {
      if let tagActivitySection = store.currectTagActivitySection {
        SectionView(
          name: String(localized: "Activities By Tags", bundle: .module),
          rightContent: { EmptyView() },
          content: {
            ActivitiesByTagView(tagActivitySection: tagActivitySection)
              .formBackgroundModifier()
          }
        )
      }
    }
  }

  @ViewBuilder
  private var monthsView: some View {
    WithPerceptionTracking {
      if !store.periods.isEmpty {
        PeriodsView(periods: store.periods)
      }
    }
  }
}
