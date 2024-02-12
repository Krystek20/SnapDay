import SwiftUI
import Resources
import ComposableArchitecture
import Models

public struct WeekdaysView: View {

  // MARK: - Properties

  @Binding private var selectedWeekdays: [Int]
  private let weekdays: [Weekday]

  // MARK: - Initialization

  public init(
    selectedWeekdays: Binding<[Int]>,
    weekdays: [Weekday]
  ) {
    self._selectedWeekdays = selectedWeekdays
    self.weekdays = weekdays
  }

  // MARK: - Views

  public var body: some View {
    HStack(spacing: 10.0) {
      ForEach(weekdays) { weekday in
        Text(weekday.name)
          .selectableTextItemStyle(isSelected: contain(for: weekday))
          .onTapGesture {
            select(weekday: weekday)
          }
      }
    }
  }

  // MARK: - Helpers

  private func contain(for weekday: Weekday) -> Bool {
    selectedWeekdays.contains(weekday.index)
  }

  private func select(weekday: Weekday) {
    if selectedWeekdays.contains(weekday.index) {
      selectedWeekdays.removeAll(where: { $0 == weekday.index })
    } else {
      selectedWeekdays.append(weekday.index)
    }
  }
}
