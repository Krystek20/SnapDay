import SwiftUI
import ComposableArchitecture
import UiComponents
import Common
import Resources
import Models

public struct DeveloperToolsView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<DeveloperToolsFeature>

  // MARK: - Initialization

  public init(store: StoreOf<DeveloperToolsFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 10.0) {
        Text("Send notifications")
        VStack(spacing: 5.0) {
          Button("Day Activity") {
            store.send(.view(.sendDayActivityReminderNotificationButtonTapped))
          }
          Button("Day Activity Task") {
            store.send(.view(.sendDayActivityTaskReminderNotificationButtonTapped))
          }
          Button("Evening summary") {
            store.send(.view(.sendEveningSummaryReminderNotificationButtonTapped))
          }
        }
      }
    }
  }
}
