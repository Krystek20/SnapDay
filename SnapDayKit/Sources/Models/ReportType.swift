import Foundation

public enum ReportType: Equatable {
  case activity(Activity, [Activity], ActivityLabel?)
  case tag(Tag, [Tag], Activity?)
}

extension ReportType {
  public var title: String {
    switch self {
    case .activity(let activity, _, _):
      activity.name
    case .tag(let tag, _, _):
      tag.name
    }
  }
}
