import SwiftUI
import Models
import UiComponents
import Resources

public struct MonthlyWeekdaysView: View {

  // MARK: - Properties

  @Binding private var weekdayOrdinal: [WeekdayOrdinal]

  // MARK: - Initialization

  public init(weekdayOrdinal: Binding<[WeekdayOrdinal]>) {
    self._weekdayOrdinal = weekdayOrdinal
  }

  // MARK: - Views

  public var body: some View {
    VStack(alignment: .leading, spacing: 10.0) {
      ForEach(WeekdayOrdinal.Position.allCases) { position in
        VStack(alignment: .leading, spacing: 2.0) {
          Text(position.name)
            .font(Fonts.Quicksand.bold.swiftUIFont(size: 12.0))
            .foregroundStyle(Colors.slateHaze.swiftUIColor)
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
            )
          )
        }
      }
    }
  }
}