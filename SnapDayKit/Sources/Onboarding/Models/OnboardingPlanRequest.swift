public struct OnboardingPlanRequest: Equatable, Sendable {

  public enum Cadence: Equatable, Sendable {
    case daily
    case weekdays
    case weekends
    case onceWeekly
  }

  public let name: String
  public let activityTitle: String?
  public let cadence: Cadence?

  public init(
    name: String,
    activityTitle: String?,
    cadence: Cadence?
  ) {
    self.name = name
    self.activityTitle = activityTitle
    self.cadence = cadence
  }

  public static let empty = Self(
    name: "",
    activityTitle: nil,
    cadence: nil
  )
}
