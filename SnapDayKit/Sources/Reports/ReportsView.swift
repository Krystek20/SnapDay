import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import Utilities
import MarkerList
import ActivityList

@MainActor
public struct ReportsView: View {

  // MARK: - Properties

  private let store: StoreOf<ReportsFeature>
  private let columns = Array(repeating: GridItem(), count: 7)

  // MARK: - Initialization

  public init(store: StoreOf<ReportsFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack(alignment: .top) {
        ScrollView {
          content(viewStore: viewStore)
            .padding(.horizontal, 15.0)
            .padding(.top, viewStore.isSwitcherDismissed ? 15.0: 65.0)
        }
        .maxWidth()
        .scrollIndicators(.hidden)
        
        if viewStore.isSwitcherDismissed {
          Divider()
        } else {
          Switcher(
            title: viewStore.switcherTitle,
            leftArrowAction: {
              viewStore.send(.view(.decreaseButtonTapped))
            },
            rightArrowAction: {
              viewStore.send(.view(.increaseButtonTapped))
            }
          )
        }
      }
      .activityBackground
      .task {
        viewStore.send(.view(.appeared))
      }
      .navigationTitle(String(localized: "Reports", bundle: .module))
      .sheet(
        store: store.scope(
          state: \.$markerList,
          action: { .markerList($0) }
        ),
        content: { store in
          NavigationStack {
            MarkerListView(store: store)
              .navigationBarTitleDisplayMode(.large)
          }
          .presentationDetents([.medium])
        }
      )
      .sheet(
        store: store.scope(
          state: \.$activityList,
          action: { .activityList($0) }
        ),
        content: { store in
          NavigationStack {
            ActivityListView(store: store)
          }
          .presentationDetents([.medium, .large])
        }
      )
    }
  }

  private func content(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      picker(viewStore: viewStore)
      customDatePickers(viewStore: viewStore)
      filtersSection(viewStore: viewStore)
      summarySection(viewStore: viewStore)
      activitiesByTag(viewStore: viewStore)
    }
    .maxWidth()
  }

  @MainActor
  private func picker(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    Picker(
      selection: viewStore.$selectedFilterPeriod,
      content: {
        ForEach(viewStore.dateFilters) { period in
          Text(period.name).tag(period)
        }
      },
      label: { EmptyView() }
    )
    .pickerStyle(.segmented)
  }

  @ViewBuilder
  private func customDatePickers(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    if viewStore.showCustomDate {
      VStack {
        DatePicker(
          selection: viewStore.$startDate,
          in: ...viewStore.endDate,
          displayedComponents: [.date],
          label: {
            Text("Start", bundle: .module)
              .formTitleTextStyle
          }
        )
        DatePicker(
          selection: viewStore.$endDate,
          in: viewStore.startDate...,
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

  private func filtersSection(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    SectionView(
      name: String(localized: "Filters", bundle: .module),
      rightContent: { EmptyView() },
      content: {
        VStack(spacing: 10.0) {
          filterByTagsView(viewStore: viewStore)
          filterByActivitiesView(viewStore: viewStore)
          filterByLabelsView(viewStore: viewStore)
        }
        .formBackgroundModifier()
      }
    )
  }

  @ViewBuilder
  private func filterByTagsView(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    if let selectedTag = viewStore.selectedTag {
      HStack(spacing: 10.0) {
        Text("Tag", bundle: .module)
          .formTitleTextStyle
        Spacer()
        MarkerView(marker: selectedTag)
          .onTapGesture {
            viewStore.send(.view(.tagTapped))
          }
      }
    }
  }

  @ViewBuilder
  private func filterByActivitiesView(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    if !viewStore.activities.isEmpty {
      HStack(spacing: 10.0) {
        Text("Activity", bundle: .module)
          .formTitleTextStyle
        Spacer()
        if let selectedActivity = viewStore.selectedActivity {
          ActivityView(activity: selectedActivity)
            .onTapGesture {
              viewStore.send(.view(.selectActivityButtonTapped))
            }
        } else {
          Button(String(localized: "Select", bundle: .module)) {
            viewStore.send(.view(.selectActivityButtonTapped))
          }
          .foregroundStyle(Color.actionBlue)
          .font(.system(size: 12.0, weight: .bold))
        }
      }
    }
  }
  
  @ViewBuilder
  private func filterByLabelsView(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    if viewStore.selectedActivity != nil {
      HStack(spacing: 10.0) {
        Text("Label", bundle: .module)
          .formTitleTextStyle
        Spacer()
        if let selectedLabel = viewStore.selectedLabel {
          MarkerView(marker: selectedLabel)
            .onTapGesture {
              viewStore.send(.view(.labelTapped))
            }
        } else {
          Button(String(localized: "Select", bundle: .module)) {
            viewStore.send(.view(.labelTapped))
          }
          .foregroundStyle(Color.actionBlue)
          .font(.system(size: 12.0, weight: .bold))
        }
      }
    }
  }

  @ViewBuilder
  private func summarySection(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    if viewStore.reportDays.count > 1 {
      SectionView(
        name: String(localized: "Summary", bundle: .module),
        rightContent: { },
        content: {
          summaryView(viewStore: viewStore)
        }
      )
    }
  }

  private func summaryView(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    LazyVStack(alignment: .leading, spacing: 10.0) {
      reportDaysView(viewStore: viewStore)
      statisticsView(viewStore: viewStore)
    }
    .maxWidth()
    .formBackgroundModifier()
  }

  private func statisticsView(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    VStack(spacing: 10.0) {
      if viewStore.summary.doneCount > .zero {
        HStack(spacing: 5.0) {
          Text("Done Count", bundle: .module)
            .formTitleTextStyle
          Spacer()
          Text("\(viewStore.summary.doneCount)")
            .font(.system(size: 12.0, weight: .bold))
            .foregroundStyle(Color.standardText)
        }
      }
      if viewStore.summary.notDoneCount > .zero {
        HStack(spacing: 5.0) {
          Text("Not Done Count", bundle: .module)
            .formTitleTextStyle
          Spacer()
          Text("\(viewStore.summary.notDoneCount)")
            .font(.system(size: 12.0, weight: .bold))
            .foregroundStyle(Color.standardText)
        }
      }
      if viewStore.summary.duration > .zero {
        HStack(spacing: 5.0) {
          Text("Total Time", bundle: .module)
            .formTitleTextStyle
          Spacer()
          Text(TimeProvider.duration(from: viewStore.summary.duration, bundle: .module) ?? "")
            .font(.system(size: 12.0, weight: .bold))
            .foregroundStyle(Color.standardText)
        }
      }
    }
  }

  private func reportDaysView(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(viewStore.reportDays) { item in
        VStack(spacing: 2.0) {
          if let title = item.title {
            Text(title)
              .font(.system(size: 12.0, weight: .semibold))
              .foregroundStyle(Color.standardText)
          }
          reportDayActivityView(item, viewStore: viewStore)
            .frame(height: 30.0)
            .clipShape(RoundedRectangle(cornerRadius: 15.0))
        }
      }
    }
  }

  @ViewBuilder
  private func reportDayActivityView(_ reportDay: ReportDay, viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    switch reportDay.dayActivity {
    case .tag(let state):
      if let tag = viewStore.selectedTag {
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
      if let activity = viewStore.selectedActivity {
        switch state {
        case .done:
          ActivityImageView(data: activity.image, size: 30.0, cornerRadius: 15.0)
        case .notDone, .planned:
          ActivityImageView(data: activity.image, size: 30.0, cornerRadius: 15.0)
            .opacity(0.2)
        case .notPlanned:
          Color.clear
        }
      }
    case .empty:
      Color.clear
    }
  }

  @MainActor
  @ViewBuilder
  private func activitiesByTag(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    if let tagActivitySection = viewStore.currectTagActivitySection {
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
