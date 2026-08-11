import Foundation
import CoreData.NSManagedObject
import Models

protocol Deduplicable: NSManagedObject {
  var version: Int32 { get }
  var deduplicatedDate: Date? { get set }
}

extension Deduplicable {
  var identifier: CVarArg? {
    value(forKey: "identifier") as? CVarArg
  }
}

extension [Deduplicable] {
  func markAsDeduplicated() {
    forEach {
      guard $0.deduplicatedDate == nil else { return }
      $0.deduplicatedDate = .now
    }
  }

  var indexToReserve: Int? {
    firstIndex(where: { $0.deduplicatedDate == nil })
  }
}

extension ActivityEntity: Deduplicable {}
extension ActivityLabelEntity: Deduplicable {}
extension ActivityTaskEntity: Deduplicable {}
extension DayActivityEntity: Deduplicable {}
extension DayActivityTaskEntity: Deduplicable {}
extension IconEntity: Deduplicable {}
extension PlanEntity: Deduplicable {}
extension PlanOccurrenceEntity: Deduplicable {}
extension PlanScheduleEntryEntity: Deduplicable {}
extension RGBColorEntity: Deduplicable {}
extension ShareEntity: Deduplicable {}
extension SharedByEntity: Deduplicable {}
extension SharedDayActivityEntity: Deduplicable {}
extension SharedDayActivityTaskEntity: Deduplicable {}
extension TagEntity: Deduplicable {}

enum SupportedDeduplicable {
  static var entities: [any Deduplicable.Type] {
    [
      ActivityEntity.self,
      ActivityLabelEntity.self,
      ActivityTaskEntity.self,
      DayActivityEntity.self,
      DayActivityTaskEntity.self,
      IconEntity.self,
      PlanEntity.self,
      PlanOccurrenceEntity.self,
      PlanScheduleEntryEntity.self,
      RGBColorEntity.self,
      TagEntity.self
    ]
  }
}
