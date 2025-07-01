import Foundation
import Dependencies

public struct TokenRepository {

  @Dependency(\.networkService) private var networkService

  public func registerToken(_ token: String, for userRecord: String) async throws {
    try await networkService.request(
      url: URLProvider.url(for: "/api/v1/register-token"),
      httpMethod: .post,
      body: .json(["token": token, "userRecordID": userRecord])
    )
  }
}

extension DependencyValues {
  public var tokenRepository: TokenRepository {
    get { self[TokenRepository.self] }
    set { self[TokenRepository.self] = newValue }
  }
}

extension TokenRepository: DependencyKey {
  public static var liveValue: TokenRepository {
    TokenRepository()
  }
}
