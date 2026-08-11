import Common
import Resources
import SwiftUI
import UiComponents
import WidgetKit

public struct PlanProgressWidgetView: View {

  private let content: PlanProgressWidgetContent
  private let calendar: Calendar
  private let locale: Locale

  public init(
    content: PlanProgressWidgetContent,
    calendar: Calendar = .autoupdatingCurrent,
    locale: Locale = .preferred
  ) {
    self.content = content
    self.calendar = calendar
    self.locale = locale
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: .zero) {
      Text(content.planName)
        .font(.system(size: 18.0, weight: .bold))
        .foregroundStyle(Color.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .layoutPriority(2)

      Text(summaryText)
        .font(.system(size: 13.0, weight: .medium))
        .foregroundStyle(Color.secondaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .layoutPriority(1)
        .padding(.top, 4.0)

      Spacer(minLength: 8.0)

      if content.state != .noActivePlan {
        HStack(alignment: .bottom, spacing: 10.0) {
          VStack(alignment: .leading, spacing: .zero) {
            Text("\(content.percentComplete)%")
              .font(.system(size: 24.0, weight: .bold))
              .foregroundStyle(Color.primaryText)
              .lineLimit(1)
              .minimumScaleFactor(0.75)

            footer
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          PlanProgressLevelsView(progress: content.fractionComplete)
            .frame(width: 65.0, height: 65.0)
        }
      } else {
        footer
      }
    }
    .padding(15.0)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .formBackgroundModifier(padding: EdgeInsets(.zero))
  }

  private var footer: some View {
    Text(footerText)
      .font(.system(size: 9.0, weight: .medium))
      .foregroundStyle(Color.sectionText)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
  }

  private var summaryText: String {
    switch content.state {
    case .noActivePlan:
      String(localized: "Create a plan", bundle: .module, locale: locale)
    case .dueToday, .partlyDoneToday, .todayComplete:
      String(
        localized: "\(content.completedTodayCount) of \(content.totalTodayCount) today",
        bundle: .module,
        locale: locale
      )
    case .noActivitiesToday:
      nextSessionText
        ?? String(localized: "No upcoming sessions", bundle: .module, locale: locale)
    }
  }

  private var footerText: String {
    guard content.state != .noActivePlan else {
      return String(localized: "Open plans", bundle: .module, locale: locale)
    }
    return String(
      localized: "\(content.completedActivityCount) of \(content.totalActivityCount) total",
      bundle: .module,
      locale: locale
    )
  }

  private var nextSessionText: String? {
    guard let date = content.nextSessionDate else { return nil }
    let session: String
    if calendar.isDate(date, inSameDayAs: content.referenceDate) {
      session = String(localized: "Today", bundle: .module, locale: locale)
    } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: content.referenceDate),
              calendar.isDate(date, inSameDayAs: tomorrow) {
      session = String(localized: "Tomorrow", bundle: .module, locale: locale)
    } else {
      let formatter = DateFormatter()
      formatter.calendar = calendar
      formatter.locale = locale
      formatter.setLocalizedDateFormatFromTemplate("EEEE")
      session = formatter.string(from: date)
    }
    return String(localized: "Next session: \(session)", bundle: .module, locale: locale)
  }

}

private struct PlanProgressLevelsView: View {

  private let progress: Double
  private let levelCount = 5

  init(progress: Double) {
    self.progress = min(max(progress, .zero), 1.0)
  }

  var body: some View {
    ZStack {
      ForEach(0..<levelCount, id: \.self) { level in
        Circle()
          .stroke(Color.actionBlue, lineWidth: 4.0)
          .opacity(0.1)
          .padding(CGFloat(level) * 5.0)

        Circle()
          .trim(from: .zero, to: levelProgress(for: level))
          .stroke(
            Color.actionBlue,
            style: StrokeStyle(lineWidth: 4.0, lineCap: .round)
          )
          .opacity(0.65)
          .rotationEffect(.degrees(-90.0))
          .padding(CGFloat(level) * 5.0)
      }

      if progress >= 1.0 {
        Circle()
          .fill(Color.actionBlue)
          .opacity(0.65)
          .padding(22.5)
      }
    }
    .accessibilityHidden(true)
  }

  private func levelProgress(for level: Int) -> CGFloat {
    let scaledProgress = CGFloat(progress) * CGFloat(levelCount)
    return min(max(scaledProgress - CGFloat(level), .zero), 1.0)
  }
}
