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

  @Dependency(\.dayActivityRepository) private var dayActivityRepository

  // MARK: - Initialization

  public init() { }

  // MARK: - Public

  public func streak(for activity: Activity) async throws -> Streak {
    let configuration = ActivitiesFetchConfiguration(
      predicates: [
        NSPredicate(format: "templateIdentifier == %@", activity.id as CVarArg),
        NSPredicate(format: "date <= %@", today as NSDate)
      ],
      sorts: [
        NSSortDescriptor(key: "date", ascending: false)
      ]
    )
    let past = Date.distantPast
    let dayActivities = try await dayActivityRepository.activities(configuration)
    var groupedByDate = Dictionary(grouping: dayActivities, by: { $0.date ?? past })
      .filter { $0.key != past }
      .sorted { $0.key < $1.key }
    var currentStreak = Int.zero

    if !groupedByDate.isEmpty {
      let firstGroup = groupedByDate.removeFirst()
      currentStreak = firstGroup.value.first(where: { $0.activity?.id == activity.id && $0.isDone }) != nil ? 1 : Int.zero
    }

    var maxStreak = currentStreak
    var lastStreak: Int?
    for group in groupedByDate {
      if group.value.first(where: { $0.activity?.id == activity.id && $0.isDone }) != nil {
        currentStreak += 1
      } else if group.key < today {
        lastStreak = currentStreak
        maxStreak = max(maxStreak, currentStreak)
        currentStreak = .zero
      }
    }
    maxStreak = max(maxStreak, currentStreak)
    lastStreak = currentStreak

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
