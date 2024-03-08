import SwiftUI
import Resources

public struct CircularProgressView: View {

  // MARK: - Properties

  private let progress: Double
  private let showPercent: Bool
  private let lineWidth: Double

  // MARK: - Initialization

  public init(
    progress: Double,
    showPercent: Bool,
    lineWidth: Double
  ) {
    self.progress = progress
    self.showPercent = showPercent
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
      if showPercent {
        Text(String(Int(progress * 100)) + "%")
          .font(.system(size: 45.0, weight: .bold))
          .foregroundStyle(Color.charcoalGray)
      }
    }
  }
}
