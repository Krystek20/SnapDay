import Foundation
import Dependencies
import Models

public struct ShareRepository {

  // MARK: - Dependecies

  @Dependency(\.coreDataStack) private var coreDataStack

  // MARK: - Public

  public func fetchAll() async throws -> [Share] {
    try await EntityHandler().fetch(Share.self)
  }

  public func fetch(userRecordName: String) async throws -> Share? {
    try await EntityHandler().fetch(Share.self, identifier: userRecordName)
  }

  public func save(share: Share) async throws {
    try await EntityHandler().save(share)
  }
}

extension DependencyValues {
  public var shareRepository: ShareRepository {
    get { self[ShareRepository.self] }
    set { self[ShareRepository.self] = newValue }
  }
}

extension ShareRepository: DependencyKey {
  public static var liveValue: ShareRepository {
    ShareRepository()
  }
}
