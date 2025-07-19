import Foundation

public actor AsyncWaiter {

  private var proccessingIdentifiers: [UUID] = []

  public init() { }

  public func executeOrWait<T>(
    for identifier: UUID,
    _ action: @Sendable () async throws -> T,
    deadline: TimeInterval = 30.0,
    interval: TimeInterval = 1.0,
    function: StaticString = #function
  ) async throws -> T {
    print("executeOrWait for: \(function) id: \(identifier)")
    var deadline = deadline
    while proccessingIdentifiers.contains(identifier) && deadline > .zero {
      print("wait for: \(function) id: \(identifier)")
      try? await Task.sleep(for: .seconds(interval))
      deadline -= interval
    }

    print("exectute for: \(function) id: \(identifier)")
    proccessingIdentifiers.append(identifier)
    defer {
      proccessingIdentifiers.removeAll(where: { $0 == identifier })
      print("done for: \(function) id: \(identifier)")
    }
    return try await action()
  }

  public func waitUntil(
    deadline: TimeInterval = 30.0,
    interval: TimeInterval = 1.0,
    action: () async throws -> Bool
  ) async throws {
    var deadline = deadline
    repeat {
      let isFound = try await action()
      print("Try again... lopping count: \(deadline) isFound: \(isFound)")
      guard !isFound else { break }
      try await Task.sleep(for: .seconds(interval))
      deadline -= interval
    } while deadline > .zero
  }
}
