import SwiftUI
import ComposableArchitecture
import Resources
import Models
import UiComponents
import SelectableList
import Utilities

public struct ActivityDetailsView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<ActivityDetailsFeature>

  // MARK: - Initialization

  public init(store: StoreOf<ActivityDetailsFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      ZStack(alignment: .top) {
        ScrollView {
          summaryView
            .maxWidth()
            .padding(.horizontal, 15.0)
            .padding(.top, 65.0)
            .padding(.bottom, 15.0)
        }
        .maxWidth()
        .scrollIndicators(.hidden)

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
      .activityBackground
      .task {
        store.send(.view(.appeared))
      }
      .navigationTitle(store.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        toolbarTitle
        toolbarContent
      }
      .sheet(item: $store.scope(state: \.selectableList, action: \.selectableList)) { store in
        NavigationStack {
          SelectableListView(store: store)
            .navigationBarTitleDisplayMode(.large)
        }
        .presentationDetents([.medium])
      }
    }
  }

  private var toolbarTitle: some ToolbarContent {
    WithPerceptionTracking {
      ToolbarItem(placement: .principal) {
        HStack(spacing: 5.0) {
          Text(store.title)
            .font(.system(size: 17.0, weight: .medium))
          Image(systemName: "chevron.down")
            .imageScale(.small)
            .fontWeight(.medium)
        }
        .onTapGesture {
          store.send(.view(.navigationTitleTapped))
        }
      }
    }
  }

  private var toolbarContent: some ToolbarContent {
    WithPerceptionTracking {
      ToolbarItem(placement: .topBarTrailing) {
        Menu(content: {
          ForEach(store.periods) { period in
            Button(
              action: {
                store.selectedPeriod = period
              },
              label: {
                Text(period.name)
              }
            )
          }
        }, label: {
          Text(store.selectedPeriod.name)
            .font(.system(size: 12.0, weight: .semibold))
            .foregroundStyle(Color.actionBlue)
            .multilineTextAlignment(.trailing)
        })
      }
    }
  }

  private var summaryView: some View {
    WithPerceptionTracking {
      LazyVStack(alignment: .leading, spacing: 15.0) {
        switch store.reportFilter {
        case .empty:
          EmptyView()
        case .activity(let activity):
          filterByActivitiesView(acitivity: activity)
        case .activityLabel(let activityLabel):
          filterByLabelsView(acitivityLabel: activityLabel)
        }

        if store.showHeaderDivider {
          Divider()
        }

        ReportDaysView(reportDaysSections: store.reportDaysSections)

        if store.showStatisticsView {
          Divider()
          statisticsView
        }
      }
      .padding(.vertical, 5.0)
      .formBackgroundModifier()
    }
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
        if let duration = DateComponentsFormatter.duration(for: .minutes(store.summary.duration)) {
          HStack(spacing: 5.0) {
            Text("Total Time", bundle: .module)
              .formTitleTextStyle
            Spacer()
            Text(duration)
              .font(.system(size: 12.0, weight: .bold))
              .foregroundStyle(Color.standardText)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func filterByLabelsView(acitivityLabel: ActivityLabel?) -> some View {
    WithPerceptionTracking {
      HStack(spacing: 10.0) {
        Text("Filter By Label", bundle: .module)
          .formTitleTextStyle
        Spacer()
        if let acitivityLabel {
          MarkerView(marker: acitivityLabel)
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

  @ViewBuilder
  private func filterByActivitiesView(acitivity: Activity?) -> some View {
    WithPerceptionTracking {
      HStack(spacing: 10.0) {
        Text("Filter By Activity", bundle: .module)
          .formTitleTextStyle
        Spacer()
        if let acitivity {
          ActivityView(activity: acitivity)
            .onTapGesture {
              store.send(.view(.activityTapped))
            }
        } else {
          Button(String(localized: "Select", bundle: .module)) {
            store.send(.view(.activityTapped))
          }
          .foregroundStyle(Color.actionBlue)
          .font(.system(size: 12.0, weight: .bold))
        }
      }
    }
  }
}
