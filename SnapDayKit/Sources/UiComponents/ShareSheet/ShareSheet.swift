import SwiftUI
import CloudKit
import Resources
import Repositories

public struct ShareSheet: UIViewControllerRepresentable {

  @Binding private var isShared: Bool
  private let shareResult: ShareResult

  public init(
    isShared: Binding<Bool>,
    shareResult: ShareResult
  ) {
    self._isShared = isShared
    self.shareResult = shareResult
  }

  public func makeUIViewController(context: Context) -> UIActivityViewController {
    let ckShare = shareResult.ckShare

    ckShare[CKShare.SystemFieldKey.title] = String(localized: "SnapDay Invitation", bundle: .module)
    if let image = UIImage(named: Images.onboardingWelcome.rawValue) {
      ckShare[CKShare.SystemFieldKey.thumbnailImageData] = image.pngData()
    }

    let itemProvider = NSItemProvider()
    itemProvider.registerCKShare(
      ckShare,
      container: shareResult.container,
      allowedSharingOptions: .standard
    )

    let configuration = UIActivityItemsConfiguration(
      itemProviders: [itemProvider]
    )

    let activityController = UIActivityViewController(
      activityItemsConfiguration: configuration
    )
    activityController.completionWithItemsHandler = { _, _, _, _ in
      isShared = false
    }

    return activityController
  }

  public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
