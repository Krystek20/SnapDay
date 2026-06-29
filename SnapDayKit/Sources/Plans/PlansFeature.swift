import ComposableArchitecture

@Reducer
public struct PlansFeature {

  // MARK: - State & Action

  @ObservableState
  public struct State: Equatable {

    var selectedSection: PlansSection = .active
    var activePlans: [Plan] = Plan.activeMocks
    var finishedPlans: [Plan] = Plan.finishedMocks
    var archivedPlans: [Plan] = Plan.archivedMocks

    public init(
      selectedSection: PlansSection = .active,
      activePlans: [Plan] = Plan.activeMocks,
      finishedPlans: [Plan] = Plan.finishedMocks,
      archivedPlans: [Plan] = Plan.archivedMocks
    ) {
      self.selectedSection = selectedSection
      self.activePlans = activePlans
      self.finishedPlans = finishedPlans
      self.archivedPlans = archivedPlans
    }
  }

  public enum Action: BindableAction, Equatable {

    public enum ViewAction: Equatable {
      case appeared
      case createPlanButtonTapped
      case planTapped(Plan.ID)
    }

    case binding(BindingAction<State>)
    case view(ViewAction)
  }

  // MARK: - Initialization

  public init() { }

  // MARK: - Body

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { _, action in
      switch action {
      case .binding:
        return .none
      case .view(.appeared):
        return .none
      case .view(.createPlanButtonTapped):
        return .none
      case .view(.planTapped):
        return .none
      }
    }
  }
}

public enum PlansSection: String, CaseIterable, Equatable, Identifiable {
  case active
  case history

  public var id: Self {
    self
  }

  var title: String.LocalizationValue {
    switch self {
    case .active:
      "Active"
    case .history:
      "History"
    }
  }
}

public struct Plan: Equatable, Identifiable {
  public let id: String
  let title: String
  let summary: String
  let activities: [String]
  let progress: Double
  let progressTitle: String

  init(
    id: String,
    title: String,
    summary: String,
    activities: [String],
    progress: Double,
    progressTitle: String
  ) {
    self.id = id
    self.title = title
    self.summary = summary
    self.activities = activities
    self.progress = progress
    self.progressTitle = progressTitle
  }
}

extension Plan {
  public static let activeMocks = [
    Plan(
      id: "learn-spanish",
      title: "Learn Spanish",
      summary: "4 of 10 planned activities complete",
      activities: ["Spanish exercise", "Read Spanish book"],
      progress: 0.43,
      progressTitle: "43%"
    ),
    Plan(
      id: "morning-mobility",
      title: "Morning Mobility",
      summary: "3 of 12 planned activities complete",
      activities: ["Mobility stretch"],
      progress: 0.28,
      progressTitle: "28%"
    ),
    Plan(
      id: "deep-work",
      title: "Deep Work",
      summary: "8 of 11 planned activities complete",
      activities: ["Focus session"],
      progress: 0.72,
      progressTitle: "72%"
    ),
    Plan(
      id: "running-base",
      title: "Running Base",
      summary: "9 of 14 planned activities complete",
      activities: ["Easy run", "Long run"],
      progress: 0.64,
      progressTitle: "64%"
    )
  ]

  public static let finishedMocks = [
    Plan(
      id: "june-strength",
      title: "June Strength",
      summary: "18 of 20 planned activities complete",
      activities: ["Strength training", "Mobility stretch"],
      progress: 0.9,
      progressTitle: "90%"
    ),
    Plan(
      id: "reading-sprint",
      title: "Reading Sprint",
      summary: "12 of 14 planned activities complete",
      activities: ["Read Spanish book"],
      progress: 0.86,
      progressTitle: "86%"
    )
  ]

  public static let archivedMocks = [
    Plan(
      id: "evening-yoga",
      title: "Evening Yoga",
      summary: "5 of 10 planned activities complete",
      activities: ["Yoga flow"],
      progress: 0.5,
      progressTitle: "50%"
    )
  ]
}
