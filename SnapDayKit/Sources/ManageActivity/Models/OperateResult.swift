import Foundation
import AIModule
import Models

enum OperateResult {
  case result(ManageActivityActionResultRequest)
  case decisition(Decision)

  init(_ action: ManageActivityAction, fetchResult: ManageActivityActionResultRequest.FetchResult) {
    self = .result(
      ManageActivityActionResultRequest(action: action, fetchResult: fetchResult)
    )
  }

  init(leafAction: ManageActivityAction, type: DecisionType, result: DecisionParameters.DecisionResult?) {
    self = .decisition(
      .leaf(
        DecisionParameters(
          leafAction,
          type: type,
          result: result
        )
      )
    )
  }
}

public struct DecisionParameters: Equatable {

  enum DecisionResult {
    case accepted
    case rejected
    case error

    init(_ decisionResult: ManageActivityActionResultRequest.DecisionResult) {
      switch decisionResult {
      case .success:
        self = .accepted
      case .userCancelled:
        self = .rejected
      case .failed:
        self = .error
      }
    }
  }

  let action: ManageActivityAction
  let decisionType: DecisionType
  let result: DecisionResult?

  init(_ action: ManageActivityAction, type: DecisionType, result: DecisionResult?) {
    self.action = action
    self.decisionType = type
    self.result = result
  }
}

public indirect enum Decision: Equatable {
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

public enum DecisionType: Equatable {
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
