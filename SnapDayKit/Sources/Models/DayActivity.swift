import Foundation

public struct DayActivity: Identifiable, Equatable, Hashable {

  // MARK: - Properties

  public let id: UUID
  public var activity: Activity
  public var doneDate: Date?
  public var duration: Int
  public var overview: String?
  public let isGeneratedAutomatically: Bool
  public var tags: [Tag]
  public var labels: [ActivityLabel]

  // MARK: - Initialization

  public init(
    id: UUID,
    activity: Activity,
    doneDate: Date?,
    duration: Int,
    overview: String?,
    isGeneratedAutomatically: Bool,
    tags: [Tag],
    labels: [ActivityLabel]
  ) {
    self.id = id
    self.activity = activity
    self.doneDate = doneDate
    self.duration = duration
    self.overview = overview
    self.isGeneratedAutomatically = isGeneratedAutomatically
    self.tags = tags
    self.labels = labels
  }
}

extension DayActivity {
  public var isDone: Bool {
    doneDate != nil
  }
}
