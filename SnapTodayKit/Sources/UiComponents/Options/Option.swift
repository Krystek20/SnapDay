import Foundation

public protocol Optionable: Identifiable, Equatable {
  var name: String { get }
}

extension Optionable {
  public var id: String { name }
}
