import SwiftUI
import ComposableArchitecture
import UiComponents
import Common
import Resources
import Models
import Utilities

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
      ScrollView {
        VStack(alignment: .leading, spacing: 10.0) {
          Text("Send notifications")
            .font(.title2)
          VStack(alignment: .leading, spacing: 5.0) {
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
          Text("Events")
            .font(.title2)
          VStack(alignment: .leading, spacing: 5.0) {
            ForEach(DeveloperToolsLogger.shared.events, id: \.self) { event in
              Text(event)
                .font(.caption)
            }
          }
        }
        Text("Scheduled events")
          .font(.title2)
        VStack(alignment: .leading, spacing: 5.0) {
          ForEach(store.pendingIdentifiers, id: \.self) { identifiers in
            Text(identifiers)
              .font(.caption)
          }
        }
      }
      .padding(.all, 20.0)
      .maxWidth()
      .onAppear {
        store.send(.view(.appeared))
      }
    }
  }
}
