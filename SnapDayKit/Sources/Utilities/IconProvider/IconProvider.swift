import Foundation
import Models
import Dependencies
import Repositories

public protocol IconProviderType {
  func getIcon(id: UUID) async -> Icon?
  func getIcons(ids: [UUID]) async -> [Icon]
  func cleanIcons() async
}

extension DependencyValues {
  public var iconProvider: IconProvider {
    get { self[IconProvider.self] }
    set { self[IconProvider.self] = newValue }
  }
}

extension IconProvider: DependencyKey {
  public static var liveValue: IconProvider {
    IconProvider()
  }
}

public actor IconProvider: IconProviderType {

  // MARK: - Dependecies

  @Dependency(\.iconRepository) private var iconRepository
  @Dependency(\.activityRepository) private var activityRepository
  @Dependency(\.dayUpdater) private var dayUpdater

  // MARK: - Properties

  private let userDefaults: UserDefaults
  private let iconWasCleanedKey = "iconWasCleanedKey"

  /// Cleanup if last cleanup interval greater than 1d
  private var shouldCleanIcons: Bool {
    guard let lastCleanDate = userDefaults.value(forKey: iconWasCleanedKey) as? Date else { return true }
    let dayInSeconds: TimeInterval = 24 * 60 * 60
    return Date().timeIntervalSince(lastCleanDate) > dayInSeconds
  }

  // MARK: - Initialization

  public init() {
    self.userDefaults = .standard
  }

  // MARK: - Public

  public func getIcon(id: UUID) async -> Icon? {
    do {
      return try await iconRepository.fetchIcon(id)
    } catch {
      print("Cannot fetch icon: \(error)")
      return nil
    }
  }

  public func getIcons(ids: [UUID]) async -> [Icon] {
    var icons = [Icon]()
    for id in ids {
      guard let icon = await getIcon(id: id) else { continue }
      icons.append(icon)
    }
    return icons
  }

  public func cleanIcons() async {
    do {
      guard shouldCleanIcons else { return }
      userDefaults.set(Date.now, forKey: iconWasCleanedKey)

      let allIcons = try await iconRepository.fetchAll()
      let allActivities = try await activityRepository.loadActivities()
      let allDayActivities = try await dayUpdater.dayActivities()

      let allActivitiesIconIds = allActivities.reduce(into: [UUID](), { result, next in
        if let iconId = next.iconId {
          result += [iconId]
        }
      })

      let allDayActivitiesIconIds = allDayActivities.reduce(into: [UUID](), { result, next in
        if let iconId = next.iconId {
          result += [iconId]
        }
      })

      let allUsedIcons = Set(allActivitiesIconIds) + allDayActivitiesIconIds
      let allExisintIconIds = Set(allIcons.compactMap(\.id))

      let identifiersToRemove = allExisintIconIds.subtracting(allUsedIcons)
      let iconsToRemove = allIcons.filter { identifiersToRemove.contains($0.id) }

      try await iconRepository.deleteIcons(iconsToRemove)
    } catch {
      print("Cannot clean icons: \(error)")
    }
  }
}
