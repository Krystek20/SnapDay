import Models

struct ScheduledPlanDay: Equatable, Identifiable {
  var id: PlanWeekday { weekday }
  let weekday: PlanWeekday
  var activities: [Activity]

  init(weekday: PlanWeekday, activities: [Activity] = []) {
    self.weekday = weekday
    self.activities = activities
  }
}
