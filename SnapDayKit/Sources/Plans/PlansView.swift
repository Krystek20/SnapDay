import ComposableArchitecture
import Models
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

        switch store.loadState {
        case .idle, .loading:
          loadingContent
        case .loaded:
          selectedSectionContent
        case .failed(let message):
          errorContent(message: message)
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
    .navigationDestination(
      item: $store.scope(state: \.planDetails, action: \.planDetails)
    ) { store in
      PlanDetailsView(store: store)
    }
    .alert(
      String(localized: "Archive this Plan?", bundle: .module),
      isPresented: archiveConfirmationBinding
    ) {
      Button(
        String(localized: "Archive Plan", bundle: .module),
        role: .destructive,
        action: { store.send(.view(.archivePlanConfirmed)) }
      )
      Button(
        String(localized: "Cancel", bundle: .module),
        role: .cancel,
        action: { store.send(.view(.archivePlanCancelled)) }
      )
    } message: {
      Text("The Plan will move to History. Completed activities and progress will be kept.", bundle: .module)
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

  @ViewBuilder
  private var selectedSectionContent: some View {
    switch store.selectedSection {
    case .active:
      activeSection
    case .history:
      historySection
    }
  }

  private var loadingContent: some View {
    ProgressView()
      .maxWidth()
      .padding(.vertical, 30.0)
  }

  private func errorContent(message: String) -> some View {
    VStack(spacing: 10.0) {
      Text("Plans couldn't be loaded", bundle: .module)
        .font(.system(size: 16.0, weight: .semibold))
        .foregroundStyle(Color.primaryText)

      Text(message)
        .font(.system(size: 13.0, weight: .regular))
        .foregroundStyle(Color.secondaryText)
        .multilineTextAlignment(.center)

      Button(
        action: {
          store.send(.view(.retryButtonTapped))
        },
        label: {
          Text("Try again", bundle: .module)
        }
      )
      .buttonStyle(PrimaryButtonStyle())
    }
    .padding(15.0)
    .maxWidth()
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
        PlansGroup(
          plans: store.activePlans,
          action: { store.send(.view(.planTapped($0))) },
          editAction: { store.send(.view(.editPlanTapped($0))) },
          archiveAction: { store.send(.view(.archivePlanTapped($0))) }
        )
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
    plans: [PlanListItem]
  ) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      PlansSectionHeader(title: title, trailingTitle: trailingTitle)
      PlansGroup(
        plans: plans,
        action: { store.send(.view(.planTapped($0))) }
      )
    }
  }

  private var archiveConfirmationBinding: Binding<Bool> {
    Binding(
      get: { store.archiveConfirmationPlanID != nil },
      set: { isPresented in
        if !isPresented {
          store.send(.view(.archivePlanCancelled))
        }
      }
    )
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

  let plans: [PlanListItem]
  let action: (Plan.ID) -> Void
  var editAction: ((Plan.ID) -> Void)? = nil
  var archiveAction: ((Plan.ID) -> Void)? = nil

  var body: some View {
    VStack(spacing: .zero) {
      ForEach(Array(plans.enumerated()), id: \.element.id) { index, item in
        PlanRow(
          item: item,
          action: { action(item.id) },
          editAction: editAction.map { editAction in
            { editAction(item.id) }
          },
          archiveAction: archiveAction.map { archiveAction in
            { archiveAction(item.id) }
          }
        )

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

  let item: PlanListItem
  let action: () -> Void
  let editAction: (() -> Void)?
  let archiveAction: (() -> Void)?

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 10.0) {
        HStack(alignment: .top, spacing: 10.0) {
          Text(item.plan.name)
            .font(.system(size: 16.0, weight: .semibold))
            .foregroundStyle(Color.primaryText)
            .lineLimit(1)
            .layoutPriority(1)

          Spacer(minLength: 10.0)

          PlanProgressBadge(title: "\(item.progress.percentComplete)%")
        }

        Text(
          "\(item.progress.completedPlannedActivityCount) of \(item.progress.totalPlannedActivityCount) planned activities complete"
        )
          .font(.system(size: 13.0, weight: .regular))
          .foregroundStyle(Color.secondaryText)
          .lineLimit(2)

        activityChips

        HStack(alignment: .center, spacing: 10.0) {
          PlanProgressBar(value: item.progress.fractionComplete)
        }
      }
      .padding(.horizontal, 15.0)
      .padding(.vertical, 15.0)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .contextMenu {
      if let editAction {
        Button(
          action: editAction,
          label: {
            Label(String(localized: "Edit", bundle: .module), systemImage: "pencil")
          }
        )
      }
      if let archiveAction {
        Button(
          role: .destructive,
          action: archiveAction,
          label: {
            Label(String(localized: "Archive Plan", bundle: .module), systemImage: "archivebox")
          }
        )
      }
    }
  }

  private var activityChips: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 5.0) {
        ForEach(item.activities) { activity in
          Chip(title: activity.name)
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
