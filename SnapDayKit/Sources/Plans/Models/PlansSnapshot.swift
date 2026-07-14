public struct PlansSnapshot: Equatable {
  let activePlans: [PlanListItem]
  let finishedPlans: [PlanListItem]
  let archivedPlans: [PlanListItem]

  init(
    activePlans: [PlanListItem],
    finishedPlans: [PlanListItem],
    archivedPlans: [PlanListItem]
  ) {
    self.activePlans = activePlans
    self.finishedPlans = finishedPlans
    self.archivedPlans = archivedPlans
  }
}
