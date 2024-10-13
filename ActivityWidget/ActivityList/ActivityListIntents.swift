import WidgetKit
import AppIntents
import WidgetActivityList
import Repositories
import Utilities

struct ListUp: AppIntent {
  static var title: LocalizedStringResource = "Move list up"
  static var description = IntentDescription("Moving list up")

  func perform() async throws -> some IntentResult {
    if ListConfiguration.currentPage > .zero {
      ListConfiguration.currentPage -= 1
    }
    return .result()
  }
}

struct ListDown: AppIntent {
  static var title: LocalizedStringResource = "Move list down"
  static var description = IntentDescription("Moving list down")

  func perform() async throws -> some IntentResult {
    ListConfiguration.currentPage += 1
    return .result()
  }
}

struct ToggleItemIntent: AppIntent {

  static var title: LocalizedStringResource = "Switch item"
  static var description = IntentDescription("Switching item state on the list")

  @Parameter(title: "Identifier")
  private var identifier: String?

  init(identifier: String) {
    self.identifier = identifier
  }

  init() {
    self.identifier = nil
  }

  func perform() async throws -> some IntentResult {
    guard let identifier else { return .result() }
    let dayActivityRepository = DayActivityRepository.liveValue
    let userNotificationCenterProvider = UserNotificationCenterProvider.liveValue
    do {
      if var dayActivity = try await dayActivityRepository.activity(identifier) {
        dayActivity.doneDate = dayActivity.doneDate == nil ? Date() : nil
        try await dayActivityRepository.saveDayActivity(dayActivity)
      } else if var dayActivityTask = try await dayActivityRepository.activityTask(identifier) {
        dayActivityTask.doneDate = dayActivityTask.doneDate == nil ? Date() : nil
        try await dayActivityRepository.saveDayActivityTask(dayActivityTask)
      }
      try await userNotificationCenterProvider.reloadReminders()
      WidgetCenter.shared.reloadAllTimelines()
    } catch {
      print(error.localizedDescription)
    }
    return .result()
  }
}

