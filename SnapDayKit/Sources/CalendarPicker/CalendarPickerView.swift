import SwiftUI
import ComposableArchitecture
import Resources
import UiComponents

@MainActor
public struct CalendarPickerView: View {

  // MARK: - Properties

  @Bindable private var store: StoreOf<CalendarPickerFeature>

  // MARK: - Initialization

  public init(store: StoreOf<CalendarPickerFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    picker
      .padding(.horizontal, 15.0)
      .maxFrame()
      .backgroundSoft
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
      .toolbarBackground(Color.backgroundSoft, for: .navigationBar)
  }

  @ViewBuilder
  private var picker: some View {
    switch store.type {
    case .singleSelection:
      datePicker
    case .multiSelection:
      multiDatePicker
    }
  }

  private var datePicker: some View {
    DatePicker(
      "",
      selection: $store.date,
      displayedComponents: [.date]
    )
    .datePickerStyle(.graphical)
    .environment(\.locale, Locale.preferred)
    .backgroundSoft
  }

  private var multiDatePicker: some View {
    MultiDatePicker(
      "",
      selection: $store.dates
    )
    .backgroundSoft
  }
}
