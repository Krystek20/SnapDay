import Foundation
import Models
import Repositories
import Dependencies

public struct Streak: Equatable {
  public let current: Int
  public let logest: Int
  public let next: Int
}

public struct StreakProvider: TodayProvidable {

  // MARK: - Dependecies

  @Dependency(\.dayRepository) private var dayRepository

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func streak(for activity: Activity) async throws -> Streak {
    let configuration = FetchConfiguration(
      predicates: {
        NSPredicate(format: "SUBQUERY(activities, $activity, $activity.activity.name == %@).@count > 0", activity.name)
        NSPredicate(format: "date <= %@", today as NSDate)
      },
      sorts: {
        NSSortDescriptor(key: "date", ascending: false)
      }
    )
    var days = try await dayRepository.loadDays(configuration)
    let firstDay = days.removeFirst()

    var currentStreak = firstDay.activities.first(where: { $0.activity?.id == activity.id && $0.isDone }) != nil ? 1 : Int.zero
    var maxStreak = firstDay.activities.first(where: { $0.activity?.id == activity.id && $0.isDone }) != nil ? 1 : Int.zero
    var lastStreak: Int?
    for day in days {
      if day.activities.first(where: { $0.activity?.id == activity.id && $0.isDone }) != nil {
        currentStreak += 1
      } else {
        if lastStreak == nil { lastStreak = currentStreak }
        maxStreak = max(maxStreak, currentStreak)
        currentStreak = .zero
      }
    }
    maxStreak = max(maxStreak, currentStreak)
    if lastStreak == nil { lastStreak = currentStreak }

    var next = Int.zero
    if let lastStreak {
      next = switch lastStreak {
      case .zero:
        .zero
      case 1...3:
        lastStreak == maxStreak ? 4 : min(4, maxStreak)
      case 4...7:
        lastStreak == maxStreak ? 8 : min(8, maxStreak)
      case 8...14:
        lastStreak == maxStreak ? 15 : min(15, maxStreak)
      case 15...30:
        lastStreak == maxStreak ? 31 : min(31, maxStreak)
      case 31...:
        lastStreak < maxStreak ? maxStreak : Int(((Double(lastStreak) / 25) + 1) * 25)
      default:
        .zero
      }
    }

    return Streak(
      current: lastStreak ?? .zero,
      logest: maxStreak,
      next: next
    )
  }
}
