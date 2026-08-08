import WidgetKit
import AppIntents
import WidgetActivityList
import Repositories
import Utilities

struct ListUp: AppIntent {
  static var title: LocalizedStringResource = "Move list up"
  static var description = IntentDescription("Scroll the activity list up.")

  func perform() async throws -> some IntentResult {
    if ListConfiguration.currentPage > .zero {
      ListConfiguration.currentPage -= 1
    }
    return .result()
  }
}

struct ListDown: AppIntent {
  static var title: LocalizedStringResource = "Move list down"
  static var description = IntentDescription("Scroll the activity list down.")

  func perform() async throws -> some IntentResult {
    ListConfiguration.currentPage += 1
    return .result()
  }
}

struct ToggleItemIntent: AppIntent {

  static var title: LocalizedStringResource = "Toggle activity"
  static var description = IntentDescription("Mark an activity as complete or incomplete.")

  @Parameter(title: "Activity ID")
  private var identifier: String?

  init(identifier: String) {
    self.identifier = identifier
  }

  init() {
    self.identifier = nil
  }

  func perform() async throws -> some IntentResult {
    guard let identifier else { return .result() }
    let dayUpdater = DayUpdater.liveValue
    let userNotificationCenterProvider = UserNotificationCenterProvider.liveValue
    do {
      if var dayActivity = try await dayUpdater.dayActivity(identifier: identifier) {
        dayActivity.doneDate = dayActivity.doneDate == nil ? Date() : nil
        try await dayUpdater.saveDayActivity(dayActivity, syncSharable: true)
      } else if var dayActivityTask = try await dayUpdater.dayActivityTask(identifier: identifier) {
        dayActivityTask.doneDate = dayActivityTask.doneDate == nil ? Date() : nil
        try await dayUpdater.saveDayActivityTask(dayActivityTask, syncSharable: true)
      }
      try await userNotificationCenterProvider.reloadReminders()
      WidgetCenter.shared.reloadAllTimelines()
    } catch {
      print(error.localizedDescription)
    }
    return .result()
  }
}
