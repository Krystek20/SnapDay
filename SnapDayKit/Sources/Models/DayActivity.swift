import Foundation

public struct DayActivity: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public let activity: Activity
  public var isDone: Bool
  public var duration: Int
  public var overview: String?
  public let isGeneratedAutomatically: Bool

  // MARK: - Initialization

  public init(
    id: UUID,
    activity: Activity,
    isDone: Bool,
    duration: Int,
    overview: String?,
    isGeneratedAutomatically: Bool
  ) {
    self.id = id
    self.activity = activity
    self.isDone = isDone
    self.duration = duration
    self.overview = overview
    self.isGeneratedAutomatically = isGeneratedAutomatically
  }
}
