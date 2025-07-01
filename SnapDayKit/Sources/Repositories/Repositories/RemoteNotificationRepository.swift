import Foundation
import Dependencies

public enum ShareAction: String, Encodable {
  case accept
}

public enum ShareUserDataKey: String, Encodable {
  case activityLogId
  case activityName
  case userName
}

public struct NotifyParticipantsRequest: Encodable {
  let userRecord: String
  let participants: [String]
  let action: ShareAction
  let userData: [ShareUserDataKey: String]

  public init(
    userRecord: String,
    participants: [String],
    action: ShareAction,
    userData: [ShareUserDataKey: String] = [:]
  ) {
    self.userRecord = userRecord
    self.participants = participants
    self.action = action
    self.userData = userData
  }
}

public struct RemoteNotificationRepository {

  @Dependency(\.networkService) private var networkService

  public func notifyParticipants(request: NotifyParticipantsRequest) async throws {
    try await networkService.request(
      url: URLProvider.url(for: "/api/v1/notify-participants"),
      httpMethod: .post,
      body: .json(request)
    )
  }
}

extension DependencyValues {
  public var remoteNotificationRepository: RemoteNotificationRepository {
    get { self[RemoteNotificationRepository.self] }
    set { self[RemoteNotificationRepository.self] = newValue }
  }
}

extension RemoteNotificationRepository: DependencyKey {
  public static var liveValue: RemoteNotificationRepository {
    RemoteNotificationRepository()
  }
}
