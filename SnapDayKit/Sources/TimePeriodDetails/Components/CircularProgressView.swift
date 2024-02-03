import SwiftUI
import Resources

struct CircularProgressView: View {

  let progress: Double

  var body: some View {
    ZStack {
      Circle()
        .stroke(Colors.actionBlue.swiftUIColor.opacity(0.3), lineWidth: 20.0)
      Circle()
        .trim(from: .zero, to: progress)
        .stroke(
          Colors.actionBlue.swiftUIColor,
          style: StrokeStyle(lineWidth: 20.0, lineCap: .round)
        )
        .rotationEffect(Angle(degrees: -90.0))
        .animation(.linear, value: progress)
      Text(String(Int(progress * 100)) + "%")
        .font(Fonts.Quicksand.bold.swiftUIFont(size: 45.0))
        .foregroundStyle(Colors.charcoalGray.swiftUIColor)
    }
  }
}
