import Foundation
import Models

extension TimePeriod {
  func completedDaysValues(until date: Date) -> [Double] {
    days
      .filter { $0.date <= date }
      .sorted(by: { $0.date < $1.date })
      .reduce(into: [Double](), { result, day in
        let value = (result.last ?? .zero) + Double(day.completedCount) / Double(plannedCount)
        result.append(value)
      })
  }
}

