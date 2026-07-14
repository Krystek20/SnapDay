struct Plan: Equatable, Identifiable {
  let id: String
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
  static let activeMocks = [
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

  static let finishedMocks = [
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

  static let archivedMocks = [
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
