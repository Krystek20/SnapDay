import AppIntents
import Models
import Repositories
import WidgetKit

struct PlanProgressAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Plan progress · Plus"
  static var description = IntentDescription("Track a specific Plan with SnapDay Plus.")

  @Parameter(title: "Plan")
  var plan: PlanWidgetEntity?

  static var parameterSummary: some ParameterSummary {
    Summary("Track \(\.$plan)")
  }
}

struct PlanWidgetEntity: AppEntity {
  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Active plan")
  static var defaultQuery = PlanWidgetEntityQuery()

  let id: UUID
  let name: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }

  init(plan: Plan) {
    self.id = plan.id
    self.name = plan.name
  }
}

struct PlanWidgetEntityQuery: EntityQuery {
  private let planRepository = PlanRepository.liveValue

  func entities(for identifiers: [Plan.ID]) async throws -> [PlanWidgetEntity] {
    var entities: [PlanWidgetEntity] = []
    for identifier in identifiers {
      if let plan = try await planRepository.plan(identifier) {
        entities.append(PlanWidgetEntity(plan: plan))
      }
    }
    return entities
  }

  func suggestedEntities() async throws -> [PlanWidgetEntity] {
    try await planRepository.loadActivePlans(.now).map(PlanWidgetEntity.init)
  }
}
