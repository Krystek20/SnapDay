import Foundation
import Models

extension DayActivityEntity {
  func setup(by dayActivity: DayActivity) {
    identifier = dayActivity.id
    isDone = dayActivity.isDone
    duration = Int32(dayActivity.duration)
    overview = dayActivity.overview
    isGeneratedAutomatically = dayActivity.isGeneratedAutomatically
  }
}
