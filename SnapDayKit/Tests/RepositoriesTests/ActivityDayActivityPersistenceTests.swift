import Dependencies
import Foundation
import Models
@testable import Repositories
import Testing

@Suite(.serialized)
struct ActivityDayActivityPersistenceTests {
  @Test
  func loadingDayActivitiesIgnoresIncompleteCloudKitRecords() async throws {
    let coreDataStack = CoreDataStack.testValue

    try await withDependencies {
      $0.coreDataStack = coreDataStack
    } operation: {
      let repository = DayActivityRepository.liveValue
      let validActivity = DayActivity(
        id: UUID(),
        date: Date(timeIntervalSinceReferenceDate: 800_000_000),
        name: "Read",
        isGeneratedAutomatically: false
      )

      try await repository.saveDayActivity(validActivity)
      let context = coreDataStack.backgroundContext
      try await context.perform {
        _ = DayActivityEntity(context: context)
        try context.save()
      }

      let activities = try await repository.dayActivities(
        configuration: ActivitiesFetchConfiguration()
      )

      #expect(activities.map(\.id) == [validActivity.id])
    }
  }

  @Test
  func updatingActivityKeepsLinkedCompletedDayActivity() async throws {
    try await withDependencies {
      $0.coreDataStack = .testValue
    } operation: {
      let activityRepository = ActivityRepository.liveValue
      let dayActivityRepository = DayActivityRepository.liveValue
      let activityID = UUID()
      let oldIconID = UUID()
      let newIconID = UUID()
      var activity = Activity(id: activityID, name: "Read", iconId: oldIconID)
      let completionDate = Date(timeIntervalSinceReferenceDate: 800_000_000)
      let dayActivity = DayActivity(
        id: UUID(),
        date: completionDate,
        activity: activity,
        name: activity.name,
        iconId: activity.iconId,
        doneDate: completionDate,
        isGeneratedAutomatically: true
      )

      try await activityRepository.saveActivity(activity)
      try await dayActivityRepository.saveDayActivity(dayActivity)
      activity.iconId = newIconID
      try await activityRepository.saveActivity(activity)

      let activities = try await activityRepository.loadActivities()
      let persistedDayActivity = try #require(
        await dayActivityRepository.dayActivities(
          configuration: ActivitiesFetchConfiguration(
            predicates: [NSPredicate(format: "identifier == %@", dayActivity.id as CVarArg)]
          )
        ).first
      )

      #expect(activities.count == 1)
      #expect(activities.first?.iconId == newIconID)
      #expect(persistedDayActivity.activity?.id == activityID)
      #expect(persistedDayActivity.activity?.iconId == newIconID)
      #expect(persistedDayActivity.doneDate == completionDate)
    }
  }
}
