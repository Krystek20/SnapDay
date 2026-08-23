import Dependencies
import Foundation
import Models
@testable import Repositories
import Testing

@Suite(.serialized)
struct EntityHandlerTests {
  @Test
  func transactionRollsBackEveryChangeWhenOperationThrows() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let handler = EntityHandler()
      let firstActivity = Activity(id: UUID(), name: "Read")
      let secondActivity = Activity(id: UUID(), name: "Walk")

      do {
        try await handler.transaction { transaction in
          try transaction.save(firstActivity)
          try transaction.save(secondActivity)
          throw TestError.expected
        }
      } catch TestError.expected {
      }

      #expect(try await handler.fetch(Activity.self, identifier: firstActivity.id as CVarArg) == nil)
      #expect(try await handler.fetch(Activity.self, identifier: secondActivity.id as CVarArg) == nil)
    }
  }

  @Test
  func transactionCommitsAllChangesWhenOperationSucceeds() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let handler = EntityHandler()
      let firstActivity = Activity(id: UUID(), name: "Read")
      let secondActivity = Activity(id: UUID(), name: "Walk")

      try await handler.transaction { transaction in
        try transaction.save([firstActivity, secondActivity])
      }

      let activities: [Activity] = try await handler.fetch(Activity.self)
      #expect(Set(activities.map(\.id)) == Set([firstActivity.id, secondActivity.id]))
    }
  }

  private enum TestError: Error {
    case expected
  }
}
