import SwiftUI
import ComposableArchitecture
import Resources
import UiComponents

@MainActor
public struct CalendarPickerView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<CalendarPickerFeature>

  // MARK: - Initialization

  public init(store: StoreOf<CalendarPickerFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithPerceptionTracking {
      picker
        .padding(.horizontal, 15.0)
        .maxFrame()
        .activityBackground
        .toolbar {
          if let buttonTitle = store.buttonTitle {
            ToolbarItem(placement: .topBarTrailing) {
              Button(buttonTitle) {
                store.send(.view(.trailingButtonTapped))
              }
              .font(.system(size: 12.0, weight: .bold))
              .foregroundStyle(Color.actionBlue)
            }
            ToolbarItem(placement: .topBarLeading) {
              Button(String(localized: "Cancel", bundle: .module)) {
                store.send(.view(.cancelButtonTapped))
              }
              .font(.system(size: 12.0, weight: .bold))
              .foregroundStyle(Color.actionBlue)
            }
          }
        }
    }
  }

  private var picker: some View {
    WithPerceptionTracking {
      switch store.type {
      case .singleSelection:
        datePicker
      case .multiSelection:
        multiDatePicker
      }
    }
  }

  private var datePicker: some View {
    WithPerceptionTracking {
      DatePicker(
        "",
        selection: $store.date,
        displayedComponents: [.date]
      )
      .datePickerStyle(.graphical)
      .activityBackground
    }
  }

  private var multiDatePicker: some View {
    WithPerceptionTracking {
      MultiDatePicker(
        "",
        selection: $store.dates
      )
      .activityBackground
    }
  }
}
