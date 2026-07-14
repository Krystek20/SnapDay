import ComposableArchitecture
import Resources
import SwiftUI
import UiComponents

@MainActor
public struct PlansView: View {

  // MARK: - Properties

  @Bindable private var store: StoreOf<PlansFeature>

  // MARK: - Initialization

  public init(store: StoreOf<PlansFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 15.0) {
        sectionPicker

        switch store.selectedSection {
        case .active:
          activeSection
        case .history:
          historySection
        }
      }
      .padding(.horizontal, 15.0)
      .padding(.top, 15.0)
      .padding(.bottom, 15.0)
    }
    .maxWidth()
    .scrollIndicators(.hidden)
    .background
    .navigationTitle(String(localized: "Plans", bundle: .module))
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(
          action: {
            store.send(.view(.createPlanButtonTapped))
          },
          label: {
            Image(systemName: "plus.circle.fill")
              .foregroundStyle(Color.actionBlue)
          }
        )
      }
    }
    .task {
      store.send(.view(.appeared))
    }
    .sheet(item: $store.scope(state: \.newPlan, action: \.newPlan)) { store in
      NewPlanView(store: store)
        .presentationDetents([.large])
        .interactiveDismissDisabled()
    }
  }

  private var sectionPicker: some View {
    Picker(
      "",
      selection: $store.selectedSection,
      content: {
        ForEach(PlansSection.allCases) { section in
          Text(String(localized: section.title, bundle: .module))
            .tag(section)
        }
      }
    )
    .pickerStyle(.segmented)
  }

  private var activeSection: some View {
    VStack(alignment: .leading, spacing: 10.0) {
      PlansSectionHeader(
        title: String(localized: "ACTIVE PLANS", bundle: .module),
        trailingTitle: "\(store.activePlans.count) active"
      )

      if store.activePlans.isEmpty {
        emptyActiveContent
      } else {
        PlansGroup(plans: store.activePlans) { id in
          store.send(.view(.planTapped(id)))
        }
      }
    }
  }

  private var emptyActiveContent: some View {
    VStack(spacing: 15.0) {
      VStack(spacing: 5.0) {
        Text("No active Plans", bundle: .module)
          .font(.system(size: 19.0, weight: .semibold))
          .foregroundStyle(Color.primaryText)
          .multilineTextAlignment(.center)

        Text("Create a Plan from your existing activities and SnapDay will add them to the right days.", bundle: .module)
          .font(.system(size: 14.0, weight: .regular))
          .foregroundStyle(Color.secondaryText)
          .multilineTextAlignment(.center)
          .lineSpacing(2.0)
      }
      .padding(.horizontal, 15.0)
      .padding(.vertical, 15.0)
      .maxWidth()
      .background(
        Color.formBackground
          .clipShape(RoundedRectangle(cornerRadius: 14.0))
      )

      Button(
        action: {
          store.send(.view(.createPlanButtonTapped))
        },
        label: {
          Text("Create your first Plan", bundle: .module)
        }
      )
      .buttonStyle(PrimaryButtonStyle())

      Text("Finished and archived Plans will appear in History.", bundle: .module)
        .font(.system(size: 13.0, weight: .regular))
        .foregroundStyle(Color.sectionText)
        .multilineTextAlignment(.center)
        .maxWidth(alignment: .center)
    }
  }

  private var historySection: some View {
    VStack(alignment: .leading, spacing: 15.0) {
      historyGroup(
        title: String(localized: "FINISHED", bundle: .module),
        trailingTitle: "\(store.finishedPlans.count) finished",
        plans: store.finishedPlans
      )

      historyGroup(
        title: String(localized: "ARCHIVED", bundle: .module),
        trailingTitle: "\(store.archivedPlans.count) archived",
        plans: store.archivedPlans
      )
      .opacity(0.85)
    }
  }

  private func historyGroup(
    title: String,
    trailingTitle: String,
    plans: [Plan]
  ) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      PlansSectionHeader(title: title, trailingTitle: trailingTitle)
      PlansGroup(plans: plans) { id in
        store.send(.view(.planTapped(id)))
      }
    }
  }
}

private struct PlansSectionHeader: View {

  let title: String
  let trailingTitle: String?

  init(title: String, trailingTitle: String? = nil) {
    self.title = title
    self.trailingTitle = trailingTitle
  }

  var body: some View {
    HStack(spacing: 10.0) {
      Text(title)
      Spacer()
      if let trailingTitle {
        Text(trailingTitle)
      }
    }
    .font(.system(size: 13.0, weight: .regular))
    .foregroundStyle(Color.sectionText)
  }
}

private struct PlansGroup: View {

  let plans: [Plan]
  let action: (Plan.ID) -> Void

  var body: some View {
    VStack(spacing: .zero) {
      ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
        PlanRow(plan: plan) {
          action(plan.id)
        }

        if index < plans.index(before: plans.endIndex) {
          Divider()
            .padding(.horizontal, 15.0)
        }
      }
    }
    .background(
      Color.formBackground
        .clipShape(RoundedRectangle(cornerRadius: 14.0))
    )
  }
}

private struct PlanRow: View {

  let plan: Plan
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 10.0) {
        HStack(alignment: .top, spacing: 10.0) {
          Text(plan.title)
            .font(.system(size: 16.0, weight: .semibold))
            .foregroundStyle(Color.primaryText)
            .lineLimit(1)
            .layoutPriority(1)

          Spacer(minLength: 10.0)

          PlanProgressBadge(title: plan.progressTitle)
        }

        Text(plan.summary)
          .font(.system(size: 13.0, weight: .regular))
          .foregroundStyle(Color.secondaryText)
          .lineLimit(2)

        activityChips

        HStack(alignment: .center, spacing: 10.0) {
          PlanProgressBar(value: plan.progress)
        }
      }
      .padding(.horizontal, 15.0)
      .padding(.vertical, 15.0)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private var activityChips: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 5.0) {
        ForEach(plan.activities, id: \.self) { activity in
          Chip(title: activity)
        }
      }
    }
    .scrollIndicators(.hidden)
  }
}

private struct PlanProgressBadge: View {

  let title: String

  var body: some View {
    Text(title)
      .font(.system(size: 12.0, weight: .bold))
      .foregroundStyle(Color.sunburstOrange)
      .lineLimit(1)
      .padding(.horizontal, 10.0)
      .padding(.vertical, 5.0)
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

private struct PlanProgressBar: View {

  let value: Double

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color.emphasisBackground)

        Capsule()
          .fill(Color.actionBlue)
          .frame(width: max(0.0, min(1.0, value)) * proxy.size.width)
      }
    }
    .frame(height: 5.0)
  }
}
