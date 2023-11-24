import SwiftUI

public struct MonthGrid: View {

  // MARK: - Properties

  private let daysInMonth: Int = 31
  private let columns = Array(repeating: GridItem(), count: 7)
  @Binding private var selectedDays: [Int]

  // MARK: - Initialization

  public init(selectedDays: Binding<[Int]>) {
    self._selectedDays = selectedDays
  }

  // MARK: - Views

  public var body: some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(1...daysInMonth, id: \.self) { day in
        Text("\(day)")
          .selectableTextItemStyle(isSelected: selectedDays.contains(day))
          .onTapGesture {
            if selectedDays.contains(day) {
              selectedDays.removeAll(where: { $0 == day })
            } else {
              selectedDays.append(day)
            }
          }
      }
    }
  }
}
