import Foundation
import AIModule
import Models

extension ToolResponse {
  init(id: String, object: Encodable, encoder: JSONEncoder = JSONEncoder()) throws {
    let data = try encoder.encode(object)
    let value = String(data: data, encoding: .utf8) ?? "Can't encode object"
    self.init(id: id, value: value)
  }
}

enum OperateResult {
  case result(UserResponse)
  case decisition(Decision)

  init(_ action: ManageActivityAction, decision: UserDecision) {
    self = .result(
      UserResponse(action: action, decision: decision)
    )
  }

  init(leafAction: ManageActivityAction, type: DecisionType, result: UserDecision?) {
    self = .decisition(
      .leaf(
        DecisionParameters(
          action: leafAction,
          type: type,
          result: result
        )
      )
    )
  }
}

struct DecisionParameters: Equatable {
  let action: ManageActivityAction
  let type: DecisionType
  let result: UserDecision?
}

indirect enum Decision: Equatable {
  case leaf(DecisionParameters)
  case chain(DecisionParameters, nextDecisions: [Decision])

  var parameters: DecisionParameters {
    switch self {
    case .leaf(let parameters): parameters
    case .chain(let parameters, _): parameters
    }
  }
}

extension [Decision] {
  var all: [Decision] {
    reduce(into: [Decision](), { result, next in
      switch next {
      case .leaf:
        result.append(next)
      case .chain(_, let nextDecisions):
        result.append(next)
        result.append(contentsOf: nextDecisions.all)
      }
    })
  }
}

enum DecisionType: Equatable {
  case createDayActivity(DayActivity)
  case updateDayActivity(DayActivity)
  case deleteDayActivity(DayActivity)
  case createDayActivityTask(DayActivity, DayActivityTask)
  case updateDayActivityTask(DayActivityTask)
  case deleteDayActivityTask(DayActivityTask)
  case createActivity(Activity)
  case updateActivity(Activity)
  case deleteActivity(Activity)
  case createActivityTask(Activity, ActivityTask)
  case updateActivityTask(Activity, ActivityTask)
  case deleteActivityTask(Activity, ActivityTask)
}
