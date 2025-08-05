#if DEBUG
import SwiftUI
import ComposableArchitecture
import UiComponents
import Common
import Resources
import Models
import Utilities
import UniformTypeIdentifiers

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
          Text("Helpers")
            .font(.title2)
          VStack(alignment: .leading, spacing: 2.0) {
            ForEach(store.allShared) { shared in
              if shared.showButton {
                Button("Clean") {
                  store.send(.view(.cleanShared(shared.sharedId)))
                }
              }
              Text(shared.sharedId)
                .font(.caption2)
              if let text = shared.text {
                Text(text)
                  .font(.caption)
              }
            }
          }
          Button("Clean Unused CKShares") {
            store.send(.view(.cleanZones))
          }
          Button("Clean Images") {
            store.send(.view(.cleanImages))
          }
          Button("Invite krystek20") {
            store.send(.view(.invite1))
          }
          Button("Invite zadumana") {
            store.send(.view(.invite2))
          }
          Button("Clean NSUbiquitousKeyValueStore") {
            store.send(.view(.cleanKeyValueStore))
          }
          Text("Send notifications")
            .font(.title2)
          Button("Day Activity") {
            store.send(.view(.sendDayActivityReminderNotificationButtonTapped))
          }
          Button("Day Activity Task") {
            store.send(.view(.sendDayActivityTaskReminderNotificationButtonTapped))
          }
          Button("Evening summary") {
            store.send(.view(.sendEveningSummaryReminderNotificationButtonTapped))
          }
          Text("Events")
            .font(.title2)
          ForEach(DeveloperToolsLogger.shared.events, id: \.self) { event in
            Text(event)
              .font(.caption)
              .onTapGesture {
                UIPasteboard.general.setValue(event, forPasteboardType: UTType.plainText.identifier)
              }
          }
          Text("Scheduled events")
            .font(.title2)
          ForEach(store.pendingIdentifiers, id: \.self) { identifiers in
            Text(identifiers)
              .font(.caption)
          }
          Text("Background scheduled events")
            .font(.title2)
          ForEach(store.pendingBackgroundTask, id: \.self) { identifiers in
            Text(identifiers)
              .font(.caption)
          }
          Toggle("Background updated notification", isOn: $store.backgroundUpdatedNotificationEnabled)
            .font(.title2)
        }
        .maxFrame()
      }
      .padding(.all, 20.0)
      .onAppear {
        store.send(.view(.appeared))
      }
    }
  }
}
#endif
