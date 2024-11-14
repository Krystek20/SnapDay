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
    ZStack(alignment: .center) {
      if progress == .zero || progress == 1.0 {
        Circle()
          .stroke(foregroundColor, lineWidth: lineWidth)
          .background(Circle().foregroundColor(foregroundColor))
      } else {
        Circle()
          .stroke(Color.actionBlueLight, lineWidth: lineWidth)
        Circle()
          .trim(from: .zero, to: progress)
          .stroke(
            Color.actionBlue,
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
          )
          .rotationEffect(Angle(degrees: -90.0))

        if progress > .zero && progress < 1.0 {
          Text("\(Int(progress * 100))")
            .font(.system(size: 8.0, weight: .bold))
            .foregroundStyle(Color.sectionText)
        }
      }
    }
  }

  private var foregroundColor: Color {
    if progress == .zero {
      Color.actionBlueLight
    } else if progress == 1.0 {
      Color.actionBlue
    } else {
      Color.clear
    }
  }
}
