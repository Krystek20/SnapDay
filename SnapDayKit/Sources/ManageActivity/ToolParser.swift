import Foundation
import Dependencies
import Repositories
import Utilities
import AIModule
import Models

struct ToolParser {

  @Dependency(\.dayUpdater) private var dayUpdater
  @Dependency(\.activityRepository) private var activityRepository
  @Dependency(\.tagRepository) private var tagRepository
  @Dependency(\.utcCalendar) private var calendar

  func actions(on tools: [ToolRequest]) async -> [ToolResponse] {
    var responses = [ToolResponse]()
    for tool in tools {
      switch tool.payload {
      case .getDayActivities(let payload):
        responses.append(await getDayActivities(tool.id, payload: payload))
      case .getDayActivity(let payload):
        responses.append(await getDayActivity(tool.id, payload: payload))
      case .getActivityTemplates:
        responses.append(await getActivityTemplates(tool.id))
      case .getActivityTemplate(let payload):
        responses.append(await getActivityTemplate(tool.id, payload: payload))
      case .getTags:
        responses.append(await getTags(tool.id))
      }
    }
    return responses
  }

  // MARK: - Getter Tools

  private func getDayActivities(_ identifier: String, payload: GetDayActivities) async -> ToolResponse {
    do {
      let date = calendar.dayFormat(payload.date)
      let configuration = ActivitiesFetchConfiguration(range: date...date)
      let dayActivities = try await dayUpdater.dayActivities(configuration: configuration)
      let dayActivityRequests = dayActivities.map(DayActivityResponse.init)
      return try ToolResponse(id: identifier, object: dayActivityRequests)
    } catch {
      return ToolResponse(id: identifier, value: error.localizedDescription)
    }
  }

  private func getDayActivity(_ identifier: String, payload: GetDayActivity) async -> ToolResponse {
    await getObject(
      for: payload.identifier.uuidString,
      toolId: identifier,
      fetcher: dayUpdater.dayActivity,
      mapper: DayActivityResponse.init
    )
  }

  private func getActivityTemplates(_ identifier: String) async -> ToolResponse {
    do {
      let activities = try await activityRepository.loadActivities()
      let activityTemplateRequests = activities.map(ActivityTemplateResponse.init)
      return try ToolResponse(id: identifier, object: activityTemplateRequests)
    } catch {
      return ToolResponse(id: identifier, value: error.localizedDescription)
    }
  }

  private func getActivityTemplate(_ identifier: String, payload: GetActivityTemplate) async -> ToolResponse {
    await getObject(
      for: payload.identifier.uuidString,
      toolId: identifier,
      fetcher: activityRepository.getActivity,
      mapper: ActivityTemplateResponse.init
    )
  }

  private func getTags(_ identifier: String) async -> ToolResponse {
    do {
      let tags = try await tagRepository.loadTags([])
      let tagsRequests = tags.map(MarkerResponse.init)
      return try ToolResponse(id: identifier, object: tagsRequests)
    } catch {
      return ToolResponse(id: identifier, value: error.localizedDescription)
    }
  }

  private func getObject<T>(
    for objectId: String,
    toolId: String,
    fetcher: @escaping (String) async throws -> T?,
    mapper: ((T) -> Encodable)
  ) async -> ToolResponse {
    do {
      guard let object = try await fetcher(objectId) else {
        throw NSError(domain: "[\(toolId)] objectNotFound: \(objectId)", code: 8888)
      }
      return try ToolResponse(id: toolId, object: mapper(object))
    } catch {
      return ToolResponse(id: toolId, value: error.localizedDescription)
    }
  }
}
