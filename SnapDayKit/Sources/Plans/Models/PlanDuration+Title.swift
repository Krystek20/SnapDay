import Foundation
import Models

extension PlanDuration {
  var title: String.LocalizationValue {
    switch self {
    case .sevenDays: "7 days"
    case .twoWeeks: "2 weeks"
    case .oneMonth: "1 month"
    case .threeMonths: "3 months"
    case .sixMonths: "6 months"
    case .oneYear: "1 year"
    case .custom: "Custom"
    }
  }
}
