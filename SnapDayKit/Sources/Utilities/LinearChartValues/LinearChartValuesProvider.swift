import Foundation
import Models

public struct LinearChartValuesProvider {

  public init() { }

  public func prepareValues(for selectedDay: Day) -> LinearChartValues {
    LinearChartValues(
      points: completedDaysValues(for: selectedDay),
      expectedPoints: selectedDay.activities.count,
      currentPoint: selectedDay.activities.filter(\.isDone).count - 1
    )
  }

  public func prepareValues(for days: [Day], until date: Date) -> LinearChartValues {
    LinearChartValues(
      points: completedDaysValues(for: days, until: date),
      expectedPoints: days.count,
      currentPoint: days.firstIndex(where: { $0.date == date })
    )
  }

  private func completedDaysValues(for selectedDay: Day) -> [Double] {
    guard selectedDay.activities.count > .zero else { return [] }
    return selectedDay.activities
      .filter(\.isDone)
      .sorted(by: { $0.doneDate ?? Date() < $1.doneDate ?? Date() })
      .enumerated()
      .reduce(into: [Double](), { result, dayActivityParameters in
        let value = Double(dayActivityParameters.offset + 1) / Double(selectedDay.activities.count)
        result.append(value)
      })
  }

  private func completedDaysValues(for days: [Day], until date: Date) -> [Double] {
    days
      .filter { $0.date <= date }
      .sorted(by: { $0.date < $1.date })
      .reduce(into: [Double](), { result, day in
        let value = (result.last ?? .zero) + Double(day.completedCount) / Double(days.plannedCount)
        result.append(value)
      })
  }
}
