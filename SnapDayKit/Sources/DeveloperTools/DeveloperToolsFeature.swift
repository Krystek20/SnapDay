//#if DEBUG
import Foundation
import ComposableArchitecture
import Repositories
import Utilities
import Models
import Common
import BackgroundTasks
import CloudKit

public struct Shared: Identifiable, Equatable {
  public let id: Int
  let sharedId: String
  let text: String?
  var showButton = false
}

@Reducer
public struct DeveloperToolsFeature: TodayProvidable {

  // MARK: - Dependencies

  @Dependency(\.dayActivityRepository) private var dayActivityRepository
  @Dependency(\.utcCalendar) private var calendar
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date) private var date
  @Dependency(\.userNotificationCenterProvider) private var userNotificationCenterProvider
  @Dependency(\.dismiss) private var dismiss

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {
    private let key = "backgroundUpdatedNotificationEnabled"
    var pendingIdentifiers: [String] = []
    var pendingBackgroundTask: [String] = []
    var backgroundUpdatedNotificationEnabled: Bool {
      get {
        UserDefaults.standard.bool(forKey: key)
      }
      set {
        UserDefaults.standard.setValue(newValue, forKey: key)
      }
    }
    var testingHostEnabled: Bool {
      get {
        UserDefaults.standard.bool(forKey: "isTestingHost")
      }
      set {
        UserDefaults.standard.setValue(newValue, forKey: "isTestingHost")
      }
    }
    var allShared: [Shared] = []
    public init() { }
  }

  public enum Action: BindableAction, Equatable {
    public enum ViewAction: Equatable {
      case appeared
      case cancelButtonTapped
      case cleanShared(String)
      case cleanKeyValueStore
      case cleanZones
      case invite1
      case invite2
      case cleanImages
      case sendDayActivityReminderNotificationButtonTapped
      case sendDayActivityTaskReminderNotificationButtonTapped
      case sendEveningSummaryReminderNotificationButtonTapped
    }
    public enum InternalAction: Equatable {
      case loadAllShared
      case setAllShared([Shared])
      case loadPendingRequests
      case loadBackgroundPendingRequests
      case setPendingIdentifiers([String])
      case setBackgroundPendingIdentifiers([String])
      case schedule(notification: DeveloperNotificiation)
    }
    public enum DelegateAction: Equatable { }

    case binding(BindingAction<State>)

    case view(ViewAction)
    case `internal`(InternalAction)
    case delegate(DelegateAction)
  }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        handleViewAction(viewAction, state: &state)
      case .internal(let internalAction):
        handleInternalAction(internalAction, state: &state)
      case .delegate:
        .none
      case .binding:
        .none
      }
    }
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Private

  private func handleViewAction(_ action: Action.ViewAction, state: inout State) -> Effect<Action> {
    switch action {
    case .cancelButtonTapped:
      return .run { _ in
        await dismiss()
      }
    case .appeared:
      return .merge(
        .send(.internal(.loadPendingRequests)),
        .send(.internal(.loadBackgroundPendingRequests)),
        .send(.internal(.loadAllShared))
      )
    case .invite1:
      return .run { send in
        NSLog("[DeveloperToolsFeature] - Invite1]")
        @Dependency(\.cloudService) var cloudService
        do {
          let url = try await cloudService.addParticipant(toEmailAddress: "krystek20@me.com")
          NSLog("[DeveloperToolsFeature] - Invitation done: \(url?.ckShare.url?.absoluteString ?? "")")
        } catch {
          NSLog("[DeveloperToolsFeature] - Invitation error: \(error)")
        }
      }
    case .invite2:
      return .run { send in
        NSLog("[DeveloperToolsFeature] - Invite2]")
        @Dependency(\.cloudService) var cloudService
        do {
          let url = try await cloudService.addParticipant(toEmailAddress: "zadumana3przez5@icloud.com")
          NSLog("[DeveloperToolsFeature] - Invitation done: \(url?.ckShare.url?.absoluteString ?? "")")
        } catch {
          NSLog("[DeveloperToolsFeature] - Invitation error: \(error)")
        }
      }
    case .cleanShared(let shareId):
      return .run { send in
        @Dependency(\.shareRepository) var shareRepository
        let shares = try await shareRepository.fetchAll()
        for share in shares where share.id == shareId {
          try await shareRepository.delete(share: share)
        }
      }
    case .cleanImages:
      return .run { send in
        @Dependency(\.iconProvider) var iconProvider
        await iconProvider.cleanIcons(force: true)
      }
    case .cleanZones:
      return .run { send in
        @Dependency(\.cloudService) var cloudService
        try await cloudService.cleanPrivateZones()
      }
    case .cleanKeyValueStore:
      let allKeys = NSUbiquitousKeyValueStore.default.dictionaryRepresentation.keys
      for key in allKeys {
          NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
      }
      return .none
    case .sendDayActivityReminderNotificationButtonTapped:
      return .run { send in
        let configuration = ActivitiesFetchConfiguration()
        let dayActivities = try await dayActivityRepository.dayActivities(configuration: configuration)
        let dayActivity = dayActivities.randomElement() ?? DayActivity(
          id: uuid(),
          date: today,
          isGeneratedAutomatically: false
        )
        let dayActivityNotification = DayActivityNotification(
          type: .activity(dayActivity),
          calendar: calendar,
          bodyTitle: "Example body title"
        )
        let notification = DeveloperNotificiation(
          identifier: uuid().uuidString,
          content: dayActivityNotification.content
        )
        await send(.internal(.schedule(notification: notification)))
      }
    case .sendDayActivityTaskReminderNotificationButtonTapped:
      return .run { send in
        let configuration = ActivitiesFetchConfiguration()
        let dayActivities = try await dayActivityRepository.dayActivities(configuration: configuration)
        guard
          let dayActivity = dayActivities.first(where: { !$0.dayActivityTasks.isEmpty }),
          let dayActivityTask = dayActivity.dayActivityTasks.randomElement()
        else { return }

        let dayActivityTaskNotification = DayActivityNotification(
          type: .activityTask(dayActivity, dayActivityTask),
          calendar: calendar,
          bodyTitle: "Example body title"
        )

        let notification = DeveloperNotificiation(
          identifier: uuid().uuidString,
          content: dayActivityTaskNotification.content
        )

        await send(.internal(.schedule(notification: notification)))
      }
    case .sendEveningSummaryReminderNotificationButtonTapped:
      return .run { send in
        let eveningSummary = EveningSummary(calendar: calendar)
        let notification = DeveloperNotificiation(
          identifier: uuid().uuidString,
          content: eveningSummary.content
        )
        await send(.internal(.schedule(notification: notification)))
      }
    }
  }

  private func handleInternalAction(_ action: Action.InternalAction, state: inout State) -> Effect<Action> {
    switch action {
    case .schedule(let notification):
      return .run { _ in
        try await userNotificationCenterProvider.schedule(
          userNotification: notification
        )
      }
    case .loadPendingRequests:
      return .run { send in
        let identifiers = await userNotificationCenterProvider.pendingRequests
        await send(.internal(.setPendingIdentifiers(identifiers)))
      }
    case .loadBackgroundPendingRequests:
      return .run { send in
        let pendingTasks = await BGTaskScheduler.shared.pendingTaskRequests().map(\.taskIdentifier)
        await send(.internal(.setBackgroundPendingIdentifiers(pendingTasks)))
      }
    case .setPendingIdentifiers(let identifiers):
      state.pendingIdentifiers = identifiers
      return .none
    case .setBackgroundPendingIdentifiers(let identifiers):
      state.pendingBackgroundTask = identifiers
      return .none
    case .loadAllShared:
      return .run { send in
        @Dependency(\.shareRepository) var shareRepository
        @Dependency(\.dayActivityRepository) var dayActivityRepository
        @Dependency(\.cloudService) var cloudService
        var shared: [Shared] = []

        let zones = try await cloudService.zones()
        for (index, zone) in zones.enumerated() {
          shared.append(Shared(id: index + 100, sharedId: zone, text: nil))
        }

        var id = Int.zero

        let allShareRepository = try await dayActivityRepository.sharedDayActivities(configuration: ActivitiesFetchConfiguration())
        var text = ""
        for activity in allShareRepository {

          let managedObject = try await cloudService.coreDataEntity(entity: activity)

          text += activity.name + "\n"
          text += activity.tasks.reduce(into: "", { result, task in
            result += "▸▸ " + task.name + " isSync: \(managedObject?.hasChanges == true)" + "\n"
          })
        }

        shared.append(Shared(id: id, sharedId: "Shared Day Activities", text: text))
        let userRecordName = await cloudService.userRecordName

        shared += try await shareRepository.fetchAll().compactMap { share in
          id += 1
          var text = "Owner: \(share.owner == userRecordName)\n"
          text += share.sharedDayActivities.reduce(into: "", { result, activity in
            result += activity.name + "\n"
            result += activity.tasks.reduce(into: "", { result, task in
              result += "▸▸ " + task.name + "\n"
            })
          })
          return Shared(id: id, sharedId: share.id, text: text, showButton: true)
        }
        await send(.internal(.setAllShared(shared)))
      }
    case .setAllShared(let shared):
      state.allShared = shared
      return .none
    }
  }
}

fileprivate extension BGTaskRequest {
  var taskIdentifier: String {
    var date = ""
    if let earliestBeginDate {
      date = "\(earliestBeginDate)"
    }
    return identifier + " - " + date
  }
}
//#endif
