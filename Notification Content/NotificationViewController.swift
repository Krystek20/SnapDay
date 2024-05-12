import UIKit
import SwiftUI
import UserNotifications
import UserNotificationsUI
import EveningSummary
import ComposableArchitecture

final class NotificationViewController: UIViewController, UNNotificationContentExtension {

  // MARK: - UNNotificationContentExtension

  func didReceive(_ notification: UNNotification) {
    addEveningSummaryView()
  }

  // MARK: - Views

  private func addEveningSummaryView() {
    var eveningSummaryView = EveningSummaryView(
      store: Store(
        initialState: EveningSummaryFeature.State(),
        reducer: { EveningSummaryFeature() }
      )
    )
    eveningSummaryView.sizeChanged = { [weak self] size in
      self?.preferredContentSize = CGSize(width: self?.preferredContentSize.width ?? .zero, height: size.height)
    }

    let hostingView = UIHostingController(rootView: eveningSummaryView)
    view.addSubview(hostingView.view)
    hostingView.view.translatesAutoresizingMaskIntoConstraints = false
    hostingView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    hostingView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    hostingView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    hostingView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
  }
}
