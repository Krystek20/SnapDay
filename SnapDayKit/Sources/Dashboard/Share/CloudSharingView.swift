import UIKit
import SwiftUI
import Repositories

struct CloudSharingView: UIViewControllerRepresentable {

  // MARK: - Properties

  @Environment(\.presentationMode) var presentationMode
  let share: Share

  // MARK: - UIViewControllerRepresentable

  func makeUIViewController(context: Context) -> some UIViewController {
    let sharingController = UICloudSharingController(share: share.ckShare, container: share.container)
    sharingController.availablePermissions = [.allowReadWrite, .allowPrivate]
    sharingController.delegate = context.coordinator
    sharingController.modalPresentationStyle = .formSheet
    return sharingController
  }

  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  // MARK: - Coordinator

  final class Coordinator: NSObject, UICloudSharingControllerDelegate {
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: any Error) {
      print(error)
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
      "Example title"
    }
  }
}
