import Foundation
import CoreData.NSManagedObject
import Models

protocol Deduplicable: NSManagedObject {
  var version: Int32 { get }
  var deduplicatedDate: Date? { get set }

  func deduplicate(to object: Deduplicable)
}

extension Deduplicable {
  var identifier: CVarArg? {
    value(forKey: "identifier") as? CVarArg
  }
}

extension [Deduplicable] {

  func deduplicate(to object: Deduplicable) {
    forEach { $0.deduplicate(to: object) }
  }

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

enum SupportedDeduplicable {
  static var entities: [any Deduplicable.Type] {
    [
      ActivityEntity.self,
      ActivityLabelEntity.self,
      ActivityTaskEntity.self,
      DayActivityEntity.self,
      DayActivityTaskEntity.self,
      IconEntity.self,
      RGBColorEntity.self,
      TagEntity.self
    ]
  }
}
