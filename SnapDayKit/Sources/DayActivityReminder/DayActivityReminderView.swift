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
        ForEach(store.items) { item in
          ListItemView(item: item)
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
    return Color.background.ignoresSafeArea()
  }
}
