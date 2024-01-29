import SwiftUI
import Resources
import ComposableArchitecture

public struct WeekdaysView: View {

  private struct Weekday: Identifiable {
    var id: String { name }
    let name: String
    let index: Int
  }

  // MARK: - Properties

  @Dependency(\.calendar) private var calendar
  @Binding private var selectedWeekdays: [Int]

  private var weekdays: [Weekday] {
    let weekdays = calendar.shortWeekdaySymbols.enumerated().map { index, name in
      Weekday(name: name, index: index + 1)
    }
    let adjustedFirstWeekday = max(calendar.firstWeekday, 1)
    return Array(weekdays.suffix(from: adjustedFirstWeekday - 1) + weekdays.prefix(adjustedFirstWeekday - 1))
  }

  // MARK: - Initialization

  public init(selectedWeekdays: Binding<[Int]>) {
    self._selectedWeekdays = selectedWeekdays
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
