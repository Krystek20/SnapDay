import Models

public enum PlanActivityResolver {

  public static func activitiesByID(_ activities: [Activity]) -> [Activity.ID: Activity] {
    Dictionary(
      activities.map { ($0.id, $0) },
      uniquingKeysWith: { _, latest in latest }
    )
  }

  public static func orderedActivities(
    for schedule: [PlanScheduleEntry],
    merging activitySources: [[Activity]]
  ) -> [Activity] {
    let activitiesByID = activitiesByID(activitySources.flatMap { $0 })
    var includedActivityIDs = Set<Activity.ID>()
    return schedule.compactMap { entry in
      guard includedActivityIDs.insert(entry.activityID).inserted else { return nil }
      return activitiesByID[entry.activityID]
    }
  }
}
