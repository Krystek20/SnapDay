import UIKit
import SwiftUI
import UserNotifications
import UserNotificationsUI
import EveningSummary
import ComposableArchitecture

final class NotificationViewController: UIViewController, UNNotificationContentExtension {

  // MARK: - Private

  private var height: NSLayoutConstraint?

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
      self?.height?.constant = size.height
      self?.view.layoutIfNeeded()
    }

    let hostingView = UIHostingController(rootView: eveningSummaryView)

    view.addSubview(hostingView.view)
    hostingView.view.translatesAutoresizingMaskIntoConstraints = false

    height = hostingView.view.heightAnchor.constraint(equalToConstant: 100.0)
    height?.isActive = true
    hostingView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    hostingView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    hostingView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    hostingView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
  }
}
