import Foundation
import Models

extension DayEntity {
  func setup(by day: Day) {
    identifier = day.id
    date = day.date
  }
}
