import SwiftUI
import Utilities

public struct DurationLabel: View {

  // MARK: - Properties

  private let duration: Int

  // MARK: - Initialization

  public init(duration: Int) {
    self.duration = duration
  }

  // MARK: - Views

  public var body: some View {
    HStack(spacing: 5.0) {
      Image(systemName: "clock")
        .foregroundStyle(Color.sectionText)
        .imageScale(.small)
      Text(TimeProvider.duration(from: duration, bundle: .module) ?? "")
        .font(.system(size: 12.0, weight: .semibold))
        .foregroundStyle(Color.sectionText)
    }
  }
}
