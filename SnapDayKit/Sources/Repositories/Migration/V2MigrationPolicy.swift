import Foundation
import Models
import CoreData.NSEntityMigrationPolicy

final class V2MigrationPolicy: NSEntityMigrationPolicy {

  private enum CustomMigrationModels: String, CaseIterable {
    case dayActivityEntity = "DayActivityEntity"
    case dayActivityTaskEntity = "DayActivityTaskEntity"
    case activityTaskEntity = "ActivityTaskEntity"
    case activityEntity = "ActivityEntity"
  }

  // MARK: - Properties

  private let encoder = JSONEncoder()

  // MARK: - NSEntityMigrationPolicy

  override func createDestinationInstances(
    forSource sInstance: NSManagedObject,
    in mapping: NSEntityMapping,
    manager: NSMigrationManager
  ) throws {
    let sourceKeys = sInstance.entity.attributesByName.keys
    let sourceValues = sInstance.dictionaryWithValues(forKeys: sourceKeys.map { $0 as String })

    guard let entityName = mapping.destinationEntityName,
          let model = CustomMigrationModels(rawValue: entityName) else {
      print("Unexpected migration of destinationEntityName: \(mapping.destinationEntityName ?? "")")
      return
    }

    let destinationInstance = NSEntityDescription.insertNewObject(
      forEntityName: entityName,
      into: manager.destinationContext
    )
    let destinationKeys = destinationInstance.entity.attributesByName.keys.map { $0 as String }

    for key in destinationKeys {
      if let value = sourceValues[key], !(value is NSNull) {
        destinationInstance.setValue(value, forKey: key)
      }
    }

    let migrateProperty: (String, String, String) -> Void = { instaceKey, entityKey, destinationKey in
      guard let value = sInstance.value(forKey: instaceKey) as? NSManagedObject,
            let entityValue = value.value(forKey: entityKey) else { return }
      destinationInstance.setValue(entityValue, forKey: destinationKey)
    }

    let migrateArray: (String, String, String) throws -> Void = { [weak self] instaceKey, entityKey, destinationKey in
      guard let values = sInstance.value(forKey: instaceKey) as? Set<NSManagedObject> else { return }
      let identifiers = values.compactMap { $0.value(forKey: entityKey) as? String }
      let dataIdentifiers = try self?.encoder.encode(identifiers)
      destinationInstance.setValue(dataIdentifiers, forKey: destinationKey)
    }

    migrateProperty("icon", "identifier", "iconIdentifier")
    destinationInstance.setValue(2, forKey: "version")

    switch model {
    case .dayActivityEntity:
      migrateProperty("day", "date", "date")
      migrateProperty("activity", "identifier", "templateIdentifier")
      try migrateArray("labels", "identifier", "labelsIdentifiers")
      try migrateArray("tags", "identifier", "tagsIdentifiers")
    case .dayActivityTaskEntity:
      migrateProperty("activityTask", "identifier", "templateIdentifier")
    case .activityTaskEntity:
      break
    case .activityEntity:
      try migrateArray("labels", "identifier", "labelsIdentifiers")
      try migrateArray("tags", "identifier", "tagsIdentifiers")
    }

    manager.associate(sourceInstance: sInstance, withDestinationInstance: destinationInstance, for: mapping)
  }
}
