import SwiftUI
import ComposableArchitecture
import UiComponents

public struct EveningSummaryView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<EveningSummaryFeature>
  public var sizeChanged: ((CGSize) -> Void)?

  // MARK: - Initialization

  public init(store: StoreOf<EveningSummaryFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      ScrollView {
        VStack(spacing: 10.0) {
          if store.showDoneView {
            VStack(spacing: 10.0) {
              Image(systemName: "medal.fill")
                .foregroundStyle(Color.green)
                .font(.system(size: 50.0))
              Text("Who's awesome? You are! 🌟 All your tasks for today are checked off. Time to kick back and enjoy your evening. You've earned it!", bundle: .module)
                .padding(.horizontal, 15.0)
                .font(.system(size: 14.0, weight: .medium))
                .multilineTextAlignment(.center)
            }
          }
          DayView(
            isPastDay: false,
            activities: store.activitiesToShow,
            completedActivities: store.completedActivities,
            dayViewShowButtonState: store.dayViewShowButtonState,
            dayViewOption: .simple(
              DayViewSimpleActions(
                activityTapped: { dayActivity in
                  store.send(.view(.activityTapped(dayActivity)))
                },
                activityTaskTapped: { dayActivity, dayActivityTask in
                  store.send(.view(.taskActivityTapped(dayActivity, dayActivityTask)))
                }
              )
            ),
            showCompletedTapped: {
              store.send(.view(.showCompletedActivitiesTapped))
            },
            hideCompletedTapped: {
              store.send(.view(.hideCompletedActivitiesTapped))
            }
          )
        }
        .background(
          GeometryReader { geometry in
            contentViewChanged(size: geometry.size)
          }
        )
      }
      .scrollIndicators(.hidden)
      .onAppear {
        store.send(.view(.appeared))
      }
    }
  }

  private func contentViewChanged(size: CGSize) -> some View {
    sizeChanged?(size)
    return Color.clear
  }
}
