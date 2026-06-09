import Repositories
import AppIntents

struct ActivityProvider: DynamicOptionsProvider {
  func results() async throws -> [String] {
    let activityRepository = ActivityRepository.liveValue
    do {
      let activities = try await activityRepository.loadActivities()
      return activities.map(\.name)
    } catch {
      return []
    }
  }
}
