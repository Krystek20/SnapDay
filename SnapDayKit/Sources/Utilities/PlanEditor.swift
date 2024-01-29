import Foundation
import Models
import Dependencies

public struct PlanEditor {
  public var composePlans: @Sendable (_ date: Date) async throws -> ()
}

extension DependencyValues {
  public var planEditor: PlanEditor {
    get { self[PlanEditor.self] }
    set { self[PlanEditor.self] = newValue }
  }
}

extension PlanEditor: DependencyKey {
  public static var liveValue: PlanEditor {
    PlanEditor(
      composePlans: { date in
        try await PlanComposer().composePlans(date: date)
      }
    )
  }

  public static var previewValue: PlanEditor {
    PlanEditor(
      composePlans: { _ in }
    )
  }
}
