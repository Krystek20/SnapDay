import SwiftUI

struct ColumnChartExplainerView: View {

  @State private var size = CGSize.zero

  var body: some View {
    VStack(alignment: .leading, spacing: 10.0) {
      VStack(alignment: .leading, spacing: 5.0) {
        indicatorView(color: .sectionText)
        textView(String(localized: "Scheduling only 80% of your day allows flexibility for unexpected tasks, reduces stress, and helps maintain sustainable productivity.", bundle: .module))
      }
      VStack(alignment: .leading, spacing: 5.0) {
        indicatorView(color: .greenSuccess)
        textView(String(localized: "Tracking time spent on completed activities versus total planned time helps you assess productivity, identify time management gaps, and improve future planning accuracy.", bundle: .module))
      }
    }
    .padding(.vertical, 10.0)
    .padding(.horizontal, 5.0)
    .extractSize(in: $size)
    .frame(height: size.height)
  }

  private func indicatorView(color: Color) -> some View {
    ZStack(alignment: .topLeading) {
      Circle()
        .frame(width: 8.0, height: 8.0)
        .foregroundColor(color)

      Path { path in
        path.move(to: CGPoint(x: .zero, y: 4.0))
        path.addLine(to: CGPoint(x: 40.0, y: 4.0))
      }
      .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [5]))
    }
  }

  private func textView(_ string: String) -> some View {
    Text(string)
      .fixedSize(horizontal: false, vertical: true)
      .font(.system(size: 10.0, weight: .medium))
      .foregroundStyle(Color.sectionText)
  }
}
