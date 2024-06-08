import UIKit
import SwiftUI
import UserNotifications
import UserNotificationsUI
import EveningSummary
import ComposableArchitecture
import DayActivityReminder
import Models

final class NotificationViewController: UIViewController, UNNotificationContentExtension {

  // MARK: - UNNotificationContentExtension

  func didReceive(_ notification: UNNotification) {
    guard let identifier = UserNotificationCategoryIdentifier(rawValue: notification.request.content.categoryIdentifier) else { return }
    switch identifier {
    case .eveningSummary:
      addEveningSummaryView(date: notification.date)
    case .dayActivityReminder:
      addDayActivityReminderView(userInfo: notification.request.content.userInfo)
    }
  }

  // MARK: - Views

  private func addEveningSummaryView(date: Date) {
    var eveningSummaryView = EveningSummaryView(
      store: Store(
        initialState: EveningSummaryFeature.State(
          date: date
        ),
        reducer: { EveningSummaryFeature() }
      )
    )
    eveningSummaryView.sizeChanged = { [weak self] size in
      self?.preferredContentSize = CGSize(width: self?.preferredContentSize.width ?? .zero, height: size.height)
    }
    addSubview(eveningSummaryView)
  }

  private func addDayActivityReminderView(userInfo: [AnyHashable: Any]) {
    guard let userInfo = userInfo as? [String: String],
          let rawValue = userInfo[DayActivityNotificationKey.kind.rawValue],
          let kind = DayActivityNotificationKind(rawValue: rawValue),
          let identifier = userInfo[DayActivityNotificationKey.identifier.rawValue] else { return }

    let type: DayActivityReminderFeature.State.DayActivityReminderType
    switch kind {
    case .activity:
      type = .activity(identifier)
    case .activityTask:
      type = .activityTask(identifier)
    }

    var dayActivityReminderView = DayActivityReminderView(
      store: Store(
        initialState: DayActivityReminderFeature.State(type: type),
        reducer: { DayActivityReminderFeature() }
      )
    )
    dayActivityReminderView.sizeChanged = { [weak self] size in
      self?.preferredContentSize = CGSize(width: self?.preferredContentSize.width ?? .zero, height: size.height)
    }
    addSubview(dayActivityReminderView)
  }

  private func addSubview(_ rootView: some View) {
    let hostingView = UIHostingController(rootView: rootView)
    view.addSubview(hostingView.view)
    hostingView.view.translatesAutoresizingMaskIntoConstraints = false
    hostingView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    hostingView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    hostingView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    hostingView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
  }
}
