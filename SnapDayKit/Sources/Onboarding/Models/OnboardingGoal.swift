import Foundation

public enum OnboardingGoal: String, CaseIterable, Equatable, Identifiable, Sendable {
  case readMore
  case moveMore
  case healthyHabit
  case learnSomething
  case createMyOwn
  case organizeMyDay

  public var id: Self { self }
}

extension OnboardingGoal {
  static let suggested: [Self] = [
    .readMore,
    .moveMore,
    .healthyHabit,
    .learnSomething
  ]

  static let additional: [Self] = [
    .createMyOwn,
    .organizeMyDay
  ]

  var title: String {
    switch self {
    case .readMore:
      String(localized: "Read more", bundle: .module)
    case .moveMore:
      String(localized: "Move more", bundle: .module)
    case .healthyHabit:
      String(localized: "Add a healthy habit", bundle: .module)
    case .learnSomething:
      String(localized: "Learn something", bundle: .module)
    case .createMyOwn:
      String(localized: "Create my own", bundle: .module)
    case .organizeMyDay:
      String(localized: "Organize my day", bundle: .module)
    }
  }

  var subtitle: String {
    switch self {
    case .readMore:
      String(localized: "15 minutes today", bundle: .module)
    case .moveMore:
      String(localized: "Take a 20-minute walk", bundle: .module)
    case .healthyHabit:
      String(localized: "Drink a glass of water in the morning", bundle: .module)
    case .learnSomething:
      String(localized: "Start with one focused session", bundle: .module)
    case .createMyOwn:
      String(localized: "Name any goal and choose a rhythm", bundle: .module)
    case .organizeMyDay:
      String(localized: "Start with today's tasks", bundle: .module)
    }
  }
}
