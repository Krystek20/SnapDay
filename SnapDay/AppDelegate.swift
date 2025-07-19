import UIKit
import CloudKit
import Repositories
import Dependencies
import Models
import Utilities
import Common

@MainActor
final class AppDelegate: UIResponder, UIApplicationDelegate {

  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider
  @Dependency(\.backgroundUpdater) private var backgroundUpdater
  @Dependency(\.dayUpdater) private var dayUpdater

  func application(
    _ application: UIApplication,
    willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    registerNotifications()
    application.registerForRemoteNotifications()
    registerBackgroundTask()
    return true
  }

  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    config.delegateClass = SceneDelegate.self
    return config
  }

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Task {
      let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
      DeveloperToolsLogger.shared.append(.token(tokenString))
      try await userNotificationCenterProvider.registerRemoteNotifications(deviceToken: tokenString)
    }
  }

  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
    print(error)
  }
}

extension AppDelegate: TodayProvidable {

  private func registerNotifications() {
    userNotificationCenterProvider.registerCategories()
  }

  private func registerBackgroundTask() {
    do {
      try backgroundUpdater.registerBackgroundTask { [weak self] in
        guard let self else { return }
        DeveloperToolsLogger.shared.append(.refresh(.runInBackground))
        _ = try await dayUpdater.day(tomorrow)
        try await userNotificationCenterProvider.reloadReminders()
        try await userNotificationCenterProvider.sendDeveloperMessage("Next day set and reminders scheduled")
        DeveloperToolsLogger.shared.append(.refresh(.setupInBackground))
      }
      DeveloperToolsLogger.shared.append(.refresh(.setup))
    } catch {
      DeveloperToolsLogger.shared.append(.refresh(.error))
    }
  }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  @Dependency(\.cloudService) private var cloudService

  func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
    Task {
      do {
        try await cloudService.accept(invitation: Invitation(cloudKitShareMetadata: cloudKitShareMetadata))
      } catch {
        print("acceptance invitation error: \(error)")
      }
    }
  }
}
