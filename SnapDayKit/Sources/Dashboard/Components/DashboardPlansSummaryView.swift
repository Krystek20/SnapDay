import SwiftUI
import Resources
import UiComponents

struct DashboardPlansSummaryView: View {

  struct Configuration {
    let title: String
    let subtitle: String?
    let progress: Progress?
    let metadata: Metadata?

    init(
      title: String,
      subtitle: String? = nil,
      progress: Progress? = nil,
      metadata: Metadata? = nil
    ) {
      self.title = title
      self.subtitle = subtitle
      self.progress = progress
      self.metadata = metadata
    }
  }

  struct Progress {
    let value: Double
    let title: String

    var normalizedValue: Double {
      min(max(value, .zero), 1.0)
    }
  }

  struct Metadata {
    let leadingText: String
    let trailingText: String?

    init(
      leadingText: String,
      trailingText: String? = nil
    ) {
      self.leadingText = leadingText
      self.trailingText = trailingText
    }
  }

  private let configuration: Configuration
  private let action: (() -> Void)?

  init(
    configuration: Configuration,
    action: (() -> Void)? = nil
  ) {
    self.configuration = configuration
    self.action = action
  }

  var body: some View {
    content
  }

  private var content: some View {
    primaryContent
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private var primaryContent: some View {
    if let action {
      Button(action: action) {
        primaryContentBody
      }
      .buttonStyle(.plain)
    } else {
      primaryContentBody
    }
  }

  private var primaryContentBody: some View {
    VStack(alignment: .leading, spacing: 15.0) {
      header
      progressSection
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 5.0) {
      titleSection

      subtitleRow
    }
  }

  @ViewBuilder
  private var subtitleRow: some View {
    if configuration.subtitle != nil || configuration.progress != nil {
      HStack(alignment: .center, spacing: 10.0) {
        if let subtitle = configuration.subtitle {
          Text(subtitle)
            .font(.system(size: 12.0, weight: .regular))
            .lineLimit(2)
            .foregroundStyle(Color.primaryText)
        }

        Spacer(minLength: 10.0)

        progressBadge
      }
    }
  }

  private var titleSection: some View {
    Text(configuration.title)
      .font(.system(size: titleFontSize, weight: .semibold))
      .lineLimit(2)
      .minimumScaleFactor(0.8)
      .foregroundStyle(Color.primaryText)
  }

  private var titleFontSize: CGFloat {
    configuration.progress == nil ? 16.0 : 18.0
  }

  @ViewBuilder
  private var progressBadge: some View {
    if let progress = configuration.progress {
      Text(progress.title)
        .font(.system(size: 12.0, weight: .bold))
        .foregroundStyle(Color.sunburstOrange)
        .lineLimit(1)
        .padding(.horizontal, 10.0)
        .padding(.vertical, 4.0)
        .background {
          Capsule()
            .fill(Color.planStatePillBackground)
        }
        .overlay {
          Capsule()
            .stroke(Color.planStatePillBorder, lineWidth: 1.0)
        }
    }
  }

  @ViewBuilder
  private var progressSection: some View {
    if configuration.progress != nil || configuration.metadata != nil {
      VStack(alignment: .leading, spacing: 10.0) {
        if let progress = configuration.progress {
          GeometryReader { proxy in
            ZStack(alignment: .leading) {
              Capsule()
                .fill(Color.emphasisBackground)
              Capsule()
                .fill(Color.actionBlue)
                .frame(width: proxy.size.width * progress.normalizedValue)
            }
          }
          .frame(height: 8.0)
        }

        if let metadata = configuration.metadata {
          HStack(spacing: 10.0) {
            Text(metadata.leadingText)
              .font(.system(size: 12.0, weight: .medium))
              .foregroundStyle(Color.sectionText)
              .lineLimit(1)

            Spacer(minLength: 10.0)

            if let trailingText = metadata.trailingText {
              Text(trailingText)
                .font(.system(size: 12.0, weight: .regular))
                .foregroundStyle(Color.secondaryText)
                .lineLimit(1)
            }
          }
        }
      }
    }
  }
}

struct DashboardPlansSectionView: View {

  private let configurations: [DashboardPlansSummaryView.Configuration]
  private let planAction: ((Int) -> Void)?
  private let allPlansAction: (() -> Void)?

  @State private var selectedIndex: Int?

  init(
    configurations: [DashboardPlansSummaryView.Configuration],
    planAction: ((Int) -> Void)? = nil,
    allPlansAction: (() -> Void)? = nil
  ) {
    self.configurations = configurations
    self.planAction = planAction
    self.allPlansAction = allPlansAction
  }

  var body: some View {
    VStack(spacing: 15.0) {
      plansContent
      Divider()
      DashboardPlansAllPlansRow(action: allPlansAction)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .formBackgroundModifier()
  }

  @ViewBuilder
  private var plansContent: some View {
    if configurations.count > 1 {
      carousel
    } else if let configuration = configurations.first {
      DashboardPlansSummaryView(
        configuration: configuration,
        action: planAction.map { action in
          { action(.zero) }
        }
      )
    }
  }

  private var carousel: some View {
    VStack(spacing: 10.0) {
      ScrollView(.horizontal) {
        HStack(spacing: 15.0) {
          ForEach(Array(configurations.enumerated()), id: \.offset) { index, configuration in
            DashboardPlansSummaryView(
              configuration: configuration,
              action: planAction.map { action in
                { action(index) }
              }
            )
            .containerRelativeFrame(.horizontal)
            .id(index)
          }
        }
        .scrollTargetLayout()
      }
      .scrollIndicators(.hidden)
      .scrollTargetBehavior(.viewAligned)
      .scrollPosition(id: $selectedIndex)

      pageIndicator
    }
  }

  private var pageIndicator: some View {
    HStack(spacing: 6.0) {
      ForEach(configurations.indices, id: \.self) { index in
        Circle()
          .fill(index == currentCarouselIndex ? Color.actionBlue : Color.emphasisBackground)
          .frame(width: 6.0, height: 6.0)
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var currentCarouselIndex: Int {
    selectedIndex ?? .zero
  }
}

private struct DashboardPlansAllPlansRow: View {

  private let action: (() -> Void)?

  init(action: (() -> Void)? = nil) {
    self.action = action
  }

  @ViewBuilder
  var body: some View {
    if let action {
      Button(action: action) {
        content
      }
      .buttonStyle(.plain)
    } else {
      content
    }
  }

  private var content: some View {
    HStack(spacing: 10.0) {
      Text("All plans", bundle: .module)
        .font(.system(size: 12.0, weight: .medium))
        .foregroundStyle(Color.primaryText)

      Spacer(minLength: 10.0)

      Image(systemName: "chevron.right")
        .font(.system(size: 12.0, weight: .bold))
        .foregroundStyle(Color.actionBlue)
    }
    .accessibilityElement(children: .combine)
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}
