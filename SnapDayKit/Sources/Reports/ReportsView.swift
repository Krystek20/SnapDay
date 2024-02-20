import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models

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
        selected: viewStore.$selectedFilterDate,
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
              if viewStore.selectedTags.contains(tag) {
                viewStore.$selectedTags.wrappedValue.removeAll(where: { $0 == tag })
              } else {
                viewStore.$selectedTags.wrappedValue.append(tag)
              }
            }
            .opacity(viewStore.selectedTags.contains(tag) ? 1.0 : 0.3)
        }
      }
    }
    .scrollIndicators(.hidden)
  }

  private func filterByActivitiesView(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      Text("Filter by activities", bundle: .module)
        .formTitleTextStyle
      activitiesList(viewStore: viewStore)
    }
  }

  private func activitiesList(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    ScrollView(.horizontal) {
      LazyHStack {
        ForEach(viewStore.activities) { activity in
          ActivityView(activity: activity)
            .onTapGesture {
              if viewStore.selectedActivities.contains(activity) {
                viewStore.$selectedActivities.wrappedValue.removeAll(where: { $0 == activity })
              } else {
                viewStore.$selectedActivities.wrappedValue.append(activity)
              }
            }
            .opacity(viewStore.selectedActivities.contains(activity) ? 1.0 : 0.3)
        }
      }
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private func selectedPeriod(viewStore: ViewStoreOf<ReportsFeature>) -> some View {
    if let filterDate = viewStore.filterDate {
      SectionView(
        name: filterDate.title,
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
        reportDayActivityView(item)
          .frame(height: 50.0)
          .onTapGesture {

          }
      }
    }
  }

  @ViewBuilder
  private func reportDayActivityView(_ reportDay: ReportDay) -> some View {
    switch reportDay.dayActivity {
    case .tags(let tags):
      VStack(spacing: .zero) {
        ForEach(tags) { tag in
          tag.rgbColor.color
        }
      }
    case .activities(let activities):
      Text("tags")
        .font(Fonts.Quicksand.bold.swiftUIFont(size: 14.0))
        .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
    }
  }
}
