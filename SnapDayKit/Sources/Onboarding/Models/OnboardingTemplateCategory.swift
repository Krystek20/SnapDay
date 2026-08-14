import Foundation

enum OnboardingTemplateCategory: Equatable, Sendable {
  case reading
  case movement
  case healthyHabit
  case learning

  var title: String {
    switch self {
    case .reading:
      String(localized: "Start with a reading plan that fits.", bundle: .module)
    case .movement:
      String(localized: "Choose a movement plan that fits.", bundle: .module)
    case .healthyHabit:
      String(localized: "Choose a healthy habit that fits.", bundle: .module)
    case .learning:
      String(localized: "Choose a learning plan that fits.", bundle: .module)
    }
  }

  var templates: [OnboardingTemplate] {
    switch self {
    case .reading:
      [
        Self.defaultReadingTemplate,
        OnboardingTemplate(
          icon: "🔖",
          title: String(localized: "Read 10 pages a day", bundle: .module),
          subtitle: String(localized: "Small daily progress.", bundle: .module),
          activityTitle: String(localized: "Read 10 pages", bundle: .module),
          cadence: .daily
        ),
        OnboardingTemplate(
          icon: "📚",
          title: String(localized: "Read before sleep", bundle: .module),
          subtitle: String(localized: "Pair reading with bedtime.", bundle: .module),
          activityTitle: String(localized: "Read before sleep", bundle: .module),
          cadence: .daily
        ),
        OnboardingTemplate(
          icon: "☕",
          title: String(localized: "Weekend reading", bundle: .module),
          subtitle: String(localized: "Longer session on weekends.", bundle: .module),
          activityTitle: String(localized: "Read", bundle: .module),
          cadence: .weekends
        )
      ]
    case .movement:
      [
        Self.defaultMovementTemplate,
        OnboardingTemplate(
          icon: "☀️",
          title: String(localized: "Stretch in the morning", bundle: .module),
          subtitle: String(localized: "Start the day with light movement.", bundle: .module),
          activityTitle: String(localized: "Stretch in the morning", bundle: .module),
          cadence: .daily
        ),
        OnboardingTemplate(
          icon: "🏋️",
          title: String(localized: "Plan one gym session", bundle: .module),
          subtitle: String(localized: "Pick a day and make it happen.", bundle: .module),
          activityTitle: String(localized: "Go to the gym", bundle: .module),
          cadence: .onceWeekly
        ),
        OnboardingTemplate(
          icon: "🌙",
          title: String(localized: "Take an evening walk", bundle: .module),
          subtitle: String(localized: "Unwind with a simple walk.", bundle: .module),
          activityTitle: String(localized: "Take an evening walk", bundle: .module),
          cadence: .daily
        )
      ]
    case .healthyHabit:
      [
        Self.defaultHealthyHabitTemplate,
        OnboardingTemplate(
          icon: "💊",
          title: String(localized: "Take daily vitamins", bundle: .module),
          subtitle: String(localized: "Pair them with your morning routine.", bundle: .module),
          activityTitle: String(localized: "Take vitamins", bundle: .module),
          cadence: .daily
        ),
        OnboardingTemplate(
          icon: "🍎",
          title: String(localized: "Eat fruit every day", bundle: .module),
          subtitle: String(localized: "Add one simple healthy choice.", bundle: .module),
          activityTitle: String(localized: "Eat a serving of fruit", bundle: .module),
          cadence: .daily
        ),
        OnboardingTemplate(
          icon: "🌙",
          title: String(localized: "Build a wind-down routine", bundle: .module),
          subtitle: String(localized: "Make space to slow down each evening.", bundle: .module),
          activityTitle: String(localized: "Wind down before bed", bundle: .module),
          cadence: .daily
        )
      ]
    case .learning:
      [
        Self.defaultLearningTemplate,
        OnboardingTemplate(
          icon: "🧠",
          title: String(localized: "Learn one concept a day", bundle: .module),
          subtitle: String(localized: "Keep progress small and memorable.", bundle: .module),
          activityTitle: String(localized: "Learn one new concept", bundle: .module),
          cadence: .daily
        ),
        OnboardingTemplate(
          icon: "🎸",
          title: String(localized: "Practice a skill on weekdays", bundle: .module),
          subtitle: String(localized: "Use a steady weekday rhythm.", bundle: .module),
          activityTitle: String(localized: "Practice a skill", bundle: .module),
          cadence: .weekdays
        ),
        OnboardingTemplate(
          icon: "🎓",
          title: String(localized: "Take one lesson a week", bundle: .module),
          subtitle: String(localized: "Choose one focused weekly session.", bundle: .module),
          activityTitle: String(localized: "Take a lesson", bundle: .module),
          cadence: .onceWeekly
        )
      ]
    }
  }

  var defaultTemplate: OnboardingTemplate {
    switch self {
    case .reading:
      Self.defaultReadingTemplate
    case .movement:
      Self.defaultMovementTemplate
    case .healthyHabit:
      Self.defaultHealthyHabitTemplate
    case .learning:
      Self.defaultLearningTemplate
    }
  }

  private static let defaultReadingTemplate = OnboardingTemplate(
    icon: "📖",
    title: String(localized: "Read 15 minutes a day", bundle: .module),
    subtitle: String(localized: "Best first step for most readers.", bundle: .module),
    activityTitle: String(localized: "Read for 15 minutes", bundle: .module),
    cadence: .daily
  )

  private static let defaultMovementTemplate = OnboardingTemplate(
    icon: "🚶",
    title: String(localized: "Take a 20-minute walk", bundle: .module),
    subtitle: String(localized: "An easy way to start moving.", bundle: .module),
    activityTitle: String(localized: "Take a 20-minute walk", bundle: .module),
    cadence: .daily
  )

  private static let defaultHealthyHabitTemplate = OnboardingTemplate(
    icon: "💧",
    title: String(localized: "Drink water every morning", bundle: .module),
    subtitle: String(localized: "Start the day with a glass of water.", bundle: .module),
    activityTitle: String(localized: "Drink a glass of water", bundle: .module),
    cadence: .daily
  )

  private static let defaultLearningTemplate = OnboardingTemplate(
    icon: "🗣️",
    title: String(localized: "Practice a language for 15 minutes", bundle: .module),
    subtitle: String(localized: "Build fluency with a short daily session.", bundle: .module),
    activityTitle: String(localized: "Practice a language for 15 minutes", bundle: .module),
    cadence: .daily
  )
}
