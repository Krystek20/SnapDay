import Foundation
import ComposableArchitecture
import Models
import Utilities
import UIKit.UIApplication

@Reducer
public struct DashboardNotificationsFeature {
  private static let promptDismissedKey = "notificationPromptDismissed"

  @Dependency(\.userNotificationCenterProvider) private var notificationCenter
  @Dependency(\.utcCalendar) private var calendar
  @Dependency(\.openURL) private var openURL

  private let userDefaults: UserDefaults

  @ObservableState
  public struct State: Equatable {
    var canRequestAuthorization = false

    public init() { }
  }

  public enum Action: Equatable {
    public enum ViewAction: Equatable {
      case promptDismissed
      case turnOnTapped
      case settingsTapped
    }

    public enum DelegateAction: Equatable {
      case reloadRequested
    }

    case start
    case refreshAuthorization
    case authorizationAvailabilityLoaded(Bool)
    case authorizationRequestCompleted
    case authorizationRequestFailed
    case reloadRemindersIfAuthorized
    case view(ViewAction)
    case delegate(DelegateAction)
  }

  public init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .start:
        return .merge(
          .send(.refreshAuthorization),
          .run { send in
            for await _ in notificationCenter.userActionStream {
              await send(.delegate(.reloadRequested))
            }
          },
          .run { send in
            for await _ in NotificationCenter.default.publisher(
              for: UIApplication.didBecomeActiveNotification
            ).values {
              await send(.refreshAuthorization)
            }
          }
        )
      case .refreshAuthorization:
        return refreshAuthorization()
      case .authorizationAvailabilityLoaded(let isAvailable):
        state.canRequestAuthorization = isAvailable
        return .none
      case .authorizationRequestCompleted:
        state.canRequestAuthorization = false
        userDefaults.set(true, forKey: Self.promptDismissedKey)
        return .none
      case .authorizationRequestFailed:
        state.canRequestAuthorization = true
        return .none
      case .reloadRemindersIfAuthorized:
        return .run { _ in await reloadRemindersIfAuthorized() }
      case .view(.promptDismissed):
        state.canRequestAuthorization = false
        userDefaults.set(true, forKey: Self.promptDismissedKey)
        return .none
      case .view(.turnOnTapped):
        state.canRequestAuthorization = false
        return requestAuthorization()
      case .view(.settingsTapped):
        return openNotificationSettingsOrRequestAuthorization()
      case .delegate:
        return .none
      }
    }
  }

  private func refreshAuthorization() -> Effect<Action> {
    .run { send in
      switch await notificationCenter.status {
      case .notDetermined:
        let isAvailable = !userDefaults.bool(forKey: Self.promptDismissedKey)
        await send(.authorizationAvailabilityLoaded(isAvailable))
      case .denied:
        await send(.authorizationAvailabilityLoaded(false))
      case .authorized:
        await send(.authorizationAvailabilityLoaded(false))
        await refreshScheduledNotifications()
      }
    }
  }

  private func requestAuthorization() -> Effect<Action> {
    .run { send in
      do {
        let isAuthorized = try await notificationCenter.requestAuthorization()
        await send(.authorizationRequestCompleted)
        guard isAuthorized else { return }
        await refreshScheduledNotifications()
      } catch {
        print("Cannot enable notifications: \(error)")
        await send(.authorizationRequestFailed)
      }
    }
  }

  private func openNotificationSettingsOrRequestAuthorization() -> Effect<Action> {
    .run { send in
      switch await notificationCenter.status {
      case .notDetermined:
        await send(.view(.turnOnTapped))
      case .authorized, .denied:
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        await openURL(settingsURL)
      }
    }
  }

  private func scheduleEveningSummaryIfAuthorized() async {
    guard case .authorized = await notificationCenter.status else { return }
    do {
      try await notificationCenter.schedule(
        userNotification: EveningSummary(calendar: calendar)
      )
    } catch {
      print("Cannot schedule evening summary: \(error)")
    }
  }

  private func reloadRemindersIfAuthorized() async {
    guard case .authorized = await notificationCenter.status else { return }
    do {
      try await notificationCenter.reloadReminders()
    } catch {
      print("Cannot reload reminders: \(error)")
    }
  }

  private func refreshScheduledNotifications() async {
    await scheduleEveningSummaryIfAuthorized()
    await reloadRemindersIfAuthorized()
  }
}
