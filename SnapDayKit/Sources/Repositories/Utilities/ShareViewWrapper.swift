import CloudKit
import UIKit

final class ShareViewWrapper: NSObject {

  private override init() {
    super.init()
  }

  static let shared = ShareViewWrapper()

  func presentCloudSharingController(share: Share) {
    let sharingController = UICloudSharingController(share: share.ckShare, container: share.container)
    sharingController.delegate = self

    guard let viewController = rootViewController else { return }
    sharingController.modalPresentationStyle = .formSheet
    viewController.present(sharingController, animated: true)
  }

  private var rootViewController: UIViewController? {
    for scene in UIApplication.shared.connectedScenes {
      if scene.activationState == .foregroundActive,
         let sceneDeleate = (scene as? UIWindowScene)?.delegate as? UIWindowSceneDelegate,
         let window = sceneDeleate.window {
        return window?.rootViewController
      }
    }
    print("\(#function): Failed to retrieve the window's root view controller.")
    return nil
  }
}

extension ShareViewWrapper: UICloudSharingControllerDelegate {
  func itemTitle(for csc: UICloudSharingController) -> String? {
    return "A cool photo!"
  }
  func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
  }
  func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
  }
  func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
    print("\(#function): Failed to save a share: \(error)")
  }
}
