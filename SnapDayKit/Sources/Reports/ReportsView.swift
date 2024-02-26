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
      ScrollView {
        content(viewStore: viewStore)
          .padding(.horizontal, 15.0)
      }
      .maxWidth()
      .scrollIndicators(.hidden)
      .activityBackground
      .task {
        viewStore.send(.view(.appeared))
      }
      .navigationTitle(String(localized: "Reports", bundle: .module))
    }
  }

  private func content(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      VStack(alignment: .leading, spacing: 10.0) {
        filterByPeriodView(viewStore: viewStore)
        filterByTagsView(viewStore: viewStore)
        filterByActivitiesView(viewStore: viewStore)
      }
      .formBackgroundModifier()
      summarySection(viewStore: viewStore)
      selectedPeriod(viewStore: viewStore)
    }
    .maxWidth()
  }

  private func filterByPeriodView(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      Text("Filter by period", bundle: .module)
        .formTitleTextStyle
      OptionsView(
        options: viewStore.dateFilters,
        selected: viewStore.$selectedFilterPeriod,
        axis: .horizontal(.center)
      )
      customDatePickers(viewStore: viewStore)
    }
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
              .font(Fonts.Quicksand.bold.swiftUIFont(size: 14.0))
              .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
            Spacer()
            Text("\(summary.doneCount)")
              .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
              .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
          }
        }
        if summary.notDoneCount > .zero {
          HStack(spacing: 5.0) {
            Text("Not Done Count", bundle: .module)
              .font(Fonts.Quicksand.bold.swiftUIFont(size: 14.0))
              .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
            Spacer()
            Text("\(summary.notDoneCount)")
              .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
              .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
          }
        }
        if summary.duration > .zero {
          HStack(spacing: 5.0) {
            Text("Total Time", bundle: .module)
              .font(Fonts.Quicksand.bold.swiftUIFont(size: 14.0))
              .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
            Spacer()
            Text(TimeProvider.duration(from: summary.duration, bundle: .module) ?? "")
              .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
              .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
          }
        }
      }
    }
    .maxWidth()
    .formBackgroundModifier()
  }

  @ViewBuilder
  private func selectedPeriod(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    if let filterDate = viewStore.filterDate {
      SectionView(
        label: {
          HStack(spacing: 10.0) {
            Button(
              action: { 
                viewStore.send(.view(.previousPeriodTapped))
              },
              label: {
                Image(systemName: "arrowshape.left")
                  .foregroundStyle(Colors.actionBlue.swiftUIColor)
                  .font(.system(size: 16.0))
              }
            )
            Text(filterDate.title)
              .font(Fonts.Quicksand.bold.swiftUIFont(size: 22.0))
              .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
            Spacer()
            Button(
              action: {
                viewStore.send(.view(.nextPeriodTapped))
              },
              label: {
                Image(systemName: "arrowshape.right")
                  .foregroundStyle(Colors.actionBlue.swiftUIColor)
                  .font(.system(size: 16.0))
              }
            )
          }
        },
        rightContent: { },
        content: {
          reportDaysView(viewStore: viewStore)
        }
      )
    }
  }

  private func reportDaysView(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(viewStore.reportDays) { item in
        VStack(spacing: 2.0) {
          if let title = item.title {
            Text(title)
              .font(Fonts.Quicksand.semiBold.swiftUIFont(size: 12.0))
              .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
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
}
