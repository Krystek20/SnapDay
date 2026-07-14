import Foundation
import Models
import Testing
@testable import Utilities

struct DayActivityTemplatePresentationTests {
  @Test
  func refreshingTemplatePresentationPreservesCompletion() {
    let activityID = UUID()
    let oldIconID = UUID()
    let newIconID = UUID()
    let completionDate = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let originalActivity = Activity(id: activityID, name: "Read", iconId: oldIconID)
    let updatedActivity = Activity(
      id: activityID,
      name: "Read a book",
      iconId: newIconID,
      important: true
    )
    var dayActivity = DayActivity(
      id: UUID(),
      date: completionDate,
      activity: originalActivity,
      name: originalActivity.name,
      iconId: originalActivity.iconId,
      doneDate: completionDate,
      duration: 30,
      isGeneratedAutomatically: true
    )
    let dayActivityID = dayActivity.id

    dayActivity.refreshTemplatePresentation(from: updatedActivity)

    #expect(dayActivity.id == dayActivityID)
    #expect(dayActivity.doneDate == completionDate)
    #expect(dayActivity.duration == 30)
    #expect(dayActivity.activity == updatedActivity)
    #expect(dayActivity.name == updatedActivity.name)
    #expect(dayActivity.iconId == newIconID)
    #expect(dayActivity.important)
  }
}
