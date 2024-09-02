import SwiftUI
import Models
import Resources

public struct MonthlyWeekdaysView: View {

  // MARK: - Properties

  @Binding private var weekdayOrdinal: [WeekdayOrdinal]
  private let weekdays: [Weekday]

  // MARK: - Initialization

  public init(
    weekdayOrdinal: Binding<[WeekdayOrdinal]>,
    weekdays: [Weekday]
  ) {
    self._weekdayOrdinal = weekdayOrdinal
    self.weekdays = weekdays
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .leading, spacing: 10.0) {
      ForEach(WeekdayOrdinal.Position.allCases) { position in
        VStack(alignment: .leading, spacing: 2.0) {
          Text(position.name)
            .font(.system(size: 12.0, weight: .bold))
            .foregroundStyle(Color.sectionText)
            .offset(x: 5.0)
          WeekdaysView(
            selectedWeekdays: Binding(
              get: { weekdayOrdinal.first(where: { $0.position == position })?.weekdays ?? [] },
              set: { value in
                if let index = weekdayOrdinal.firstIndex(where: { $0.position == position }) {
                  weekdayOrdinal[index].weekdays = value
                } else {
                  weekdayOrdinal.append(
                    WeekdayOrdinal(position: position, weekdays: value)
                  )
                }
              }
            ),
            weekdays: weekdays
          )
        }
      }
    }
  }
}
