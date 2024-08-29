import Foundation
import Dependencies
import Models

public final class FirstLaunchCreator {

  private let isFirstLaunchKey = "isFirstLaunch"
  private let initialActivitiesUrl = "https://krystek20.github.io/SnapDay/initial_activities_%@.json"
  private let supportedLanguagesUrl = "https://krystek20.github.io/SnapDay/supported_languages.json"
  private var supportedLanguages: [String] = []
  private let defaultLanguageIdentifier = "en"

  // MARK: - Properties

  private let userDefaults: UserDefaults
  private let preferredLanguages: [String]
  @Dependency(\.activityRepository) private var activityRepository
  @Dependency(\.urlSession) private var urlSession

  private lazy var jsonDecoder: JSONDecoder = {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.dateDecodingStrategy = .iso8601
    return jsonDecoder
  }()

  // MARK: - Initialization

  public init(
    userDefaults: UserDefaults = .standard,
    preferredLanguages: [String] = Locale.preferredLanguages
  ) {
    self.userDefaults = userDefaults
    self.preferredLanguages = preferredLanguages
  }

  // MARK: - Public

  public func configure() async throws {
    guard !userDefaults.bool(forKey: isFirstLaunchKey) else { return }
    defer { userDefaults.setValue(true, forKey: isFirstLaunchKey) }
    try await fetchSupportedLanguages()
    try await prepareSavedActivities()
  }

  // MARK: - Private

  private func fetchSupportedLanguages() async throws {
    guard let url = URL(string: supportedLanguagesUrl) else { return }
    let (data, response) = try await urlSession.data(from: url)
    guard let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 else { return }
    supportedLanguages = (try? jsonDecoder.decode([String].self, from: data)) ?? []
  }

  private func prepareSavedActivities() async throws {
    let preferredLanguageIdentifier = preferredLanguages
      .compactMap { $0.components(separatedBy: "-").first }
      .first(where: { supportedLanguages.contains($0) }) ?? defaultLanguageIdentifier
    guard let url = URL(string: String(format: initialActivitiesUrl, preferredLanguageIdentifier)) else { return }
    let (data, _) = try await urlSession.data(from: url)
    let activities = try jsonDecoder.decode([Activity].self, from: data)
    for activity in activities {
      try await activityRepository.saveActivity(activity)
    }
  }
}
