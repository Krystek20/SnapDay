import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources
import Models
import Utilities

@MainActor
public struct ReportsView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<ReportsFeature>
  @State private var isShowingPopover = false

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
      .background
      .task {
        store.send(.view(.appeared))
      }
      .navigationTitle(String(localized: "Reports", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        toolbarContent
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

  private var content: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: 10.0) {
        progressViewSection
        if store.timePeriodTags.count > .zero {
          tagsGridView
        }
        if store.timePeriodActivities.count > .zero {
          activitiesGridView
        }
      }
      .maxWidth()
    }
  }

  @ViewBuilder
  private var progressViewSection: some View {
    WithPerceptionTracking {
      VStack(spacing: 25.0) {
        if let periodSummaryData = store.periodSummaryData {
          PeriodSummaryView(periodSummaryData: periodSummaryData)
        }

        if let linearChartValues = store.linearChartValues {
          VStack(alignment: .leading, spacing: 10.0) {
            Text("Your Journey of Completed Activities", bundle: .module)
              .font(.system(size: 14.0, weight: .medium))
              .foregroundStyle(Color.primaryText)
            LinearChartView(
              points: linearChartValues.points,
              expectedPoints: linearChartValues.expectedPoints,
              currentPoint: linearChartValues.currentPoint
            )
            .frame(height: 100.0)
          }
          .padding(.bottom, 10.0)
        }

        if let periodSummaryData = store.periodSummaryData {
          VStack(alignment: .leading, spacing: 10.0) {
            totalTimeTitleHeader
            PeriodsView(periodSummaryData: periodSummaryData)
            PeriodDataSummaryView(periodSummaryData: periodSummaryData)
              .padding(.top, 5.0)
          }
        }
      }
      .padding(.vertical, 15.0)
      .formBackgroundModifier()
    }
  }

  private var totalTimeTitleHeader: some View {
    HStack(spacing: 10.0) {
      Text("Total Time Spent on Tracked Activities", bundle: .module)
        .font(.system(size: 14.0, weight: .medium))
        .foregroundStyle(Color.primaryText)
      Spacer()

      Button(
        action: {
          isShowingPopover = true
        },
        label: {
          Image(systemName: "info.circle")
            .foregroundStyle(Color.actionBlue)
            .imageScale(.medium)
        }
      )
      .popover(isPresented: $isShowingPopover, attachmentAnchor: .point(.leading), arrowEdge: .trailing) {
        if #available(iOS 16.4, *) {
          ColumnChartExplainerView()
            .presentationCompactAdaptation(.popover)
        } else {
          ColumnChartExplainerView()
        }
      }
    }
  }

  private var tagsGridView: some View {
    SectionView(
      name: String(localized: "Tags", bundle: .module),
      content: {
        WithPerceptionTracking {
          ActivitySummaryGrid(
            timePeriodActivities: store.timePeriodTags,
            itemTapped: { timePeriodActivity in
              store.send(.view(.tagTapped(timePeriodActivity)))
            }
          )
        }
      }
    )
  }

  private var activitiesGridView: some View {
    SectionView(
      name: String(localized: "Activities", bundle: .module),
      content: {
        WithPerceptionTracking {
          ActivitySummaryGrid(
            timePeriodActivities: store.timePeriodActivities,
            itemTapped: { timePeriodActivity in
              store.send(.view(.activityTapped(timePeriodActivity)))
            }
          )
        }
      }
    )
  }
}
