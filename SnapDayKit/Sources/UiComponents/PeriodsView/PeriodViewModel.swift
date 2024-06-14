import Foundation

public struct PeriodViewModel: Identifiable {

  // MARK: - Properties

  public let id: UUID
  let label: String
  let completedValue: Double
  let percent: Int

  // MARK: - Initialization

  public init(
    id: UUID,
    label: String,
    completedValue: Double,
    percent: Int
  ) {
    self.id = id
    self.label = label
    self.completedValue = completedValue
    self.percent = percent
  }
}
