import Foundation

public actor AsyncWaiter {

  private var proccessingIdentifiers: [UUID] = []

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
}
