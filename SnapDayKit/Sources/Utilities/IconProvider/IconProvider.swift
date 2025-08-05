import Foundation
import Models
import Dependencies
import Repositories
import Combine

public protocol IconProviderType {
  func getIcon(id: UUID) async -> Icon?
  func getIcons(ids: [UUID]) async -> [Icon]
  func cleanIcons(force: Bool) async
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
  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.dayUpdater) private var dayUpdater
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date.now) private var now

  // MARK: - Properties

  nonisolated public var iconChangedPublisher: AnyPublisher<UUID, Never> {
    iconChangedSubject.eraseToAnyPublisher()
  }
  nonisolated private let iconChangedSubject = PassthroughSubject<UUID, Never>()

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

  public func createIcon(
    from iconId: UUID?
  ) async -> Icon {
    var existingIcon: Icon?
    if let iconId {
      existingIcon = await getIcon(id: iconId)
    }

    let icon = Icon(
      id: uuid(),
      data: existingIcon?.data,
      lastUpdated: existingIcon?.lastUpdated
    )
    await saveIcon(icon)
    return icon
  }

  public func updateIcon(with iconId: UUID, byIconId: UUID?) async {
    guard var updatedIcon = await getIcon(id: iconId) else {
      print("UpdatedIcon does not exist")
      return
    }
    if let byIconId, let byIcon = await getIcon(id: byIconId) {
      guard byIcon.lastUpdated.orPast > updatedIcon.lastUpdated.orPast else { return }
      updatedIcon.data = byIcon.data
      updatedIcon.lastUpdated = byIcon.lastUpdated
    } else {
      updatedIcon.data = nil
      updatedIcon.lastUpdated = now
    }
    await saveIcon(updatedIcon)
    Task { @MainActor in
      iconChangedSubject.send(iconId)
    }
  }

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

  public func cleanIcons(force: Bool = false) async {
    do {
      guard shouldCleanIcons || force else { return }
      userDefaults.set(Date.now, forKey: iconWasCleanedKey)

      let allIcons = try await iconRepository.fetchAll()
      let allActivities = try await activityRepository.loadActivities()
      let allDayActivities = try await dayUpdater.dayActivities()
      let allSharedDayActivities = try await dayActivityRepository.sharedDayActivities(configuration: ActivitiesFetchConfiguration())

      let allActivitiesIconIds = allActivities.compactMap(\.iconId)
      let allDayActivitiesIconIds = allDayActivities.compactMap(\.iconId)
      let allSharedActivitiesIconIds = allSharedDayActivities.map(\.iconId)

      let allUsedIcons = Set(allActivitiesIconIds + allSharedActivitiesIconIds + allDayActivitiesIconIds)
      let allExisintIconIds = Set(allIcons.compactMap(\.id))

      let identifiersToRemove = allExisintIconIds.subtracting(allUsedIcons)
      let iconsToRemove = allIcons.filter { identifiersToRemove.contains($0.id) }

      try await iconRepository.deleteIcons(iconsToRemove)
    } catch {
      print("Cannot clean icons: \(error)")
    }
  }

  // MARK: - Private

  private func saveIcon(_ icon: Icon) async {
    do {
      try await iconRepository.saveIcon(icon)
    } catch {
      print("Cannot save icon: \(error)")
    }
  }
}
