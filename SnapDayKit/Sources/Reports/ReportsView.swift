import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import Utilities

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
    }
  }

  private func content(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      picker(viewStore: viewStore)
      customDatePickers(viewStore: viewStore)
      VStack(alignment: .leading, spacing: 10.0) {
        filterByTagsView(viewStore: viewStore)
        filterByActivitiesView(viewStore: viewStore)
      }
      .formBackgroundModifier()
      summarySection(viewStore: viewStore)
      reportDaysView(viewStore: viewStore)
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

  private func filterByTagsView(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      Text("Filter by tags", bundle: .module)
        .formTitleTextStyle
      tagsList(viewStore: viewStore)
    }
  }

  private func tagsList(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    ScrollView(.horizontal) {
      LazyHStack {
        ForEach(viewStore.tags) { tag in
          TagView(tag: tag)
            .onTapGesture {
              viewStore.$selectedTag.wrappedValue = tag
            }
            .opacity(viewStore.selectedTag == tag ? 1.0 : 0.3)
        }
      }
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private func filterByActivitiesView(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    if !viewStore.activities.isEmpty {
      VStack(alignment: .leading, spacing: 10.0) {
        Text("Filter by activities", bundle: .module)
          .formTitleTextStyle
        activitiesList(viewStore: viewStore)
      }
    }
  }

  private func activitiesList(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    ScrollView(.horizontal) {
      LazyHStack {
        ForEach(viewStore.activities) { activity in
          ActivityView(activity: activity)
            .onTapGesture {
              if viewStore.selectedActivity == activity {
                viewStore.$selectedActivity.wrappedValue = nil
              } else {
                viewStore.$selectedActivity.wrappedValue = activity
              }
            }
            .opacity(viewStore.selectedActivity == activity ? 1.0 : 0.3)
        }
      }
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private func summarySection(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    if !viewStore.summary.isZero {
      SectionView(
        name: String(localized: "Summary", bundle: .module),
        rightContent: { },
        content: {
          summaryView(summary: viewStore.summary)
        }
      )
    }
  }

  private func summaryView(summary: ReportSummary) -> some View {
    LazyVStack(alignment: .leading, spacing: 10.0) {
      VStack(spacing: 10.0) {
        if summary.doneCount > .zero {
          HStack(spacing: 5.0) {
            Text("Done Count", bundle: .module)
              .font(.system(size: 14.0, weight: .bold))
              .foregroundStyle(Color.deepSpaceBlue)
            Spacer()
            Text("\(summary.doneCount)")
              .font(.system(size: 12.0, weight: .bold))
              .foregroundStyle(Color.deepSpaceBlue)
          }
        }
        if summary.notDoneCount > .zero {
          HStack(spacing: 5.0) {
            Text("Not Done Count", bundle: .module)
              .font(.system(size: 14.0, weight: .bold))
              .foregroundStyle(Color.deepSpaceBlue)
            Spacer()
            Text("\(summary.notDoneCount)")
              .font(.system(size: 12.0, weight: .bold))
              .foregroundStyle(Color.deepSpaceBlue)
          }
        }
        if summary.duration > .zero {
          HStack(spacing: 5.0) {
            Text("Total Time", bundle: .module)
              .font(.system(size: 14.0, weight: .bold))
              .foregroundStyle(Color.deepSpaceBlue)
            Spacer()
            Text(TimeProvider.duration(from: summary.duration, bundle: .module) ?? "")
              .font(.system(size: 12.0, weight: .bold))
              .foregroundStyle(Color.deepSpaceBlue)
          }
        }
      }
    }
    .maxWidth()
    .formBackgroundModifier()
  }

  private func reportDaysView(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(viewStore.reportDays) { item in
        VStack(spacing: 2.0) {
          if let title = item.title {
            Text(title)
              .font(.system(size: 12.0, weight: .semibold))
              .foregroundStyle(Color.deepSpaceBlue)
          }
          reportDayActivityView(item, viewStore: viewStore)
            .frame(height: 30.0)
        }
      }
    }
  }

  @ViewBuilder
  private func reportDayActivityView(_ reportDay: ReportDay, viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    switch reportDay.dayActivity {
    case .tag(let isDone):
      if let tag = viewStore.selectedTag {
        tag.rgbColor.color.opacity(isDone ? 1.0 : 0.3)
      }
    case .activity(let isDone):
      if let activity = viewStore.selectedActivity {
        ActivityImageView(data: activity.image, size: 30.0, cornerRadius: 15.0)
          .opacity(isDone ? 1.0 : 0.3)
      }
    case .empty, .notPlanned:
      Color.clear
    }
  }

  @MainActor
  @ViewBuilder
  private func activitiesByTag(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    if !viewStore.tagActivitySections.isEmpty {
      SectionView(
        name: String(localized: "Activities By Tags", bundle: .module),
        rightContent: { EmptyView() },
        content: {
          ActivitiesByTagView(
            selectedTag: viewStore.$selectedTagActivity,
            tagActivitySections: viewStore.tagActivitySections
          )
          .formBackgroundModifier()
        }
      )
    }
  }
}
