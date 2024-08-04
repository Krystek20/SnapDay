import SwiftUI
import ComposableArchitecture
import UiComponents
import Utilities
import Models

public struct DayActivityReminderView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<DayActivityReminderFeature>
  public var sizeChanged: ((CGSize) -> Void)?

  // MARK: - Initialization

  public init(store: StoreOf<DayActivityReminderFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      VStack(alignment: .leading, spacing: .zero) {
        if let type = store.viewType {
          switch type {
          case .activity(let dayActivity):
            DayActivityRow(
              activityItem: DayActivityItem(activityType: dayActivity),
              trailingIcon: .none
            )
          case .activityTask(let dayActivity, let dayActivityTask):
            VStack(spacing: .zero) {
              DayActivityRow(
                activityItem: DayActivityItem(activityType: dayActivity),
                trailingIcon: .none
              )
              Divider()
                .padding(.leading, 20.0)
              DayActivityRow(
                activityItem: DayActivityItem(activityType: dayActivityTask),
                trailingIcon: .none
              )
              .padding(.leading, 10.0)
            }
          }
        }
      }
      .background(
        GeometryReader { geometry in
          contentViewChanged(size: geometry.size)
        }
      )
      .onAppear {
        store.send(.view(.appeared))
      }
    }
  }

  private func contentViewChanged(size: CGSize) -> some View {
    sizeChanged?(size)
    return Color.background
      .ignoresSafeArea()
  }
}
