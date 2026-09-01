import SwiftUI
import CloudKit
import Resources
import Repositories
import Common

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

    Telemetry.breadcrumb("share_sheet_presented", data: ["delivery": "cloudkit"])
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
    activityController.completionWithItemsHandler = { activityType, completed, _, error in
      if let error {
        NSLog("[ShareSheet] Invitation sharing failed: \(error)")
        Telemetry.capture(error, stage: "share_sheet")
      } else {
        NSLog("[ShareSheet] Invitation sharing finished; activity: \(activityType?.rawValue ?? "none"), completed: \(completed)")
        Telemetry.breadcrumb(completed ? "share_sheet_completed" : "share_sheet_cancelled")
      }
      Task { @MainActor in
        isShared = false
      }
    }

    return activityController
  }

  public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
