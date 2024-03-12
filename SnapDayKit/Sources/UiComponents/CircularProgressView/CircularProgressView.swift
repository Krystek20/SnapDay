import SwiftUI
import Resources

public struct CircularProgressView: View {

  // MARK: - Properties

  private let progress: Double
  private let lineWidth: Double

  // MARK: - Initialization

  public init(
    progress: Double,
    lineWidth: Double
  ) {
    self.progress = progress
    self.lineWidth = lineWidth
  }

  // MARK: - Views

  public var body: some View {
    ZStack {
      Circle()
        .stroke(Color.actionBlue.opacity(0.3), lineWidth: lineWidth)
      Circle()
        .trim(from: .zero, to: progress)
        .stroke(
          Color.actionBlue,
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(Angle(degrees: -90.0))
    }
  }
}
