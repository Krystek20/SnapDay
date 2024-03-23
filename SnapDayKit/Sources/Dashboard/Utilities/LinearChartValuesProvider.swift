import Foundation
import Models

struct LinearChartValuesProvider {

  func prepareValues(for selectedDay: Day) -> LinearChartValues {
    LinearChartValues(
      points: completedDaysValues(for: selectedDay),
      expectedPoints: selectedDay.activities.count,
      currentPoint: selectedDay.activities.filter(\.isDone).count - 1
    )
  }

  func prepareValues(for timePeriod: TimePeriod, selectedDay: Day, until date: Date) -> LinearChartValues {
    LinearChartValues(
      points: completedDaysValues(for: timePeriod, until: date),
      expectedPoints: timePeriod.days.count,
      currentPoint: selectedDay.date <= date
      ? timePeriod.days.firstIndex(of: selectedDay) ?? .zero
      : timePeriod.days.lastIndex(where: { $0.activities.contains(where: { $0.isDone }) }) ?? .zero
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

  private func completedDaysValues(for timePeriod: TimePeriod, until date: Date) -> [Double] {
    timePeriod.days
      .filter { $0.date <= date }
      .sorted(by: { $0.date < $1.date })
      .reduce(into: [Double](), { result, day in
        let value = (result.last ?? .zero) + Double(day.completedCount) / Double(timePeriod.plannedCount)
        result.append(value)
      })
  }
}
