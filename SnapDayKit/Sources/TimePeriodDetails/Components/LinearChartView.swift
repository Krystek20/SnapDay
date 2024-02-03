import SwiftUI
import Resources

struct LinearChartView: View {

  let points: [Double]
  let expectedPoints: Int
  let verticalUnits = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]

  var body: some View {
    HStack(spacing: .zero) {
      GeometryReader { proxy in
        ZStack {
          percentView(proxy: proxy)
          expectedPath(proxy: proxy)
            .foregroundColor(Colors.actionBlue.swiftUIColor.opacity(0.3))
          progressPath(proxy: proxy)
            .foregroundColor(Colors.actionBlue.swiftUIColor)
          Circle()
            .fill(Colors.actionBlue.swiftUIColor)
            .frame(width: 10.0, height: 10.0)
            .position(position(for: points.last ?? .zero, index: points.count, proxy: proxy))
        }
      }
    }
  }

  private func percentView(proxy: GeometryProxy) -> some View {
    ZStack(alignment: .topLeading) {
      ForEach(verticalUnits, id: \.self) { percent in
        let lastPosition = position(for: percent, index: points.count, proxy: proxy)
        horizontalLine(for: lastPosition.y, proxy: proxy)
        Text(String(Int(percent * 100)) + "%")
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 10.0))
          .foregroundStyle(Colors.charcoalGray.swiftUIColor)
          .offset(y: lastPosition.y)
      }
    }
  }

  private func expectedPath(proxy: GeometryProxy) -> some Shape {
    Path { path in
      path.move(to: CGPoint(x: .zero, y: proxy.size.height))
      path.addLine(to: CGPoint(x: proxy.size.width, y: .zero))
    }
    .stroke(style: StrokeStyle(lineWidth: 2.0, dash: [10, 5]))
  }

  private func progressPath(proxy: GeometryProxy) -> some Shape {
    Path { path in
      path.move(to: CGPoint(x: .zero, y: proxy.size.height))
      if expectedPoints > .zero {
        for (index, point) in points.enumerated() {
          path.addLine(to: position(for: point, index: index + 1, proxy: proxy))
        }
      }
    }
    .stroke(lineWidth: 2.0)
  }

  private func horizontalLine(for yPosition: Double, proxy: GeometryProxy) -> some View {
    Path { path in
      path.move(to: CGPoint(x: .zero, y: yPosition))
      path.addLine(to: CGPoint(x: proxy.size.width, y: yPosition))
    }
    .stroke(lineWidth: 1.0)
    .foregroundColor(Colors.charcoalGray.swiftUIColor.opacity(0.2))
  }

  private func position(for point: Double, index: Int, proxy: GeometryProxy) -> CGPoint {
    let xPosition = proxy.size.width * Double(index) / Double(expectedPoints)
    let yPosition = proxy.size.height - proxy.size.height * point
    return CGPoint(x: xPosition, y: yPosition)
  }
}
