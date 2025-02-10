import UIKit
import CloudKit
import Repositories
import Dependencies

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
      _ application: UIApplication,
      configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  @Dependency(\.dayActivityRepository) private var dayActivityRepository

  func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
    Task {
      do {
        try await dayActivityRepository.accept(Invitation(cloudKitShareMetadata: cloudKitShareMetadata))
      } catch {
        print("acceptance invitation error: \(error)")
      }
    }
  }
}
