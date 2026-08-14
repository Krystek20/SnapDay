import ComposableArchitecture
import Plans
import Resources
import SwiftUI
import UiComponents

public struct OnboardingView: View {

  @Bindable private var store: StoreOf<OnboardingFeature>

  public init(store: StoreOf<OnboardingFeature>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      ScrollView {
        VStack(alignment: .leading, spacing: 5.0) {
          header
          goalOptions(OnboardingGoal.suggested)

          Text("More options", bundle: .module)
            .font(.footnote)
            .textCase(.uppercase)
            .foregroundStyle(Color.sectionText)
            .padding(.top, 5.0)

          goalOptions(OnboardingGoal.additional)
        }
        .padding(.horizontal, 15.0)
        .padding(.top, 10.0)
        .padding(.bottom, 15.0)
      }
      .scrollIndicators(.hidden)
      .background(Color.background)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(
            String(localized: "Skip", bundle: .module),
            action: { store.send(.view(.skipButtonTapped)) }
          )
          .foregroundStyle(Color.actionBlue)
        }
      }
      .safeAreaInset(edge: .bottom) {
        Button(
          String(localized: "Continue", bundle: .module),
          action: { store.send(.view(.continueButtonTapped)) }
        )
        .buttonStyle(PrimaryButtonStyle())
        .disabled(store.selectedGoal == nil)
        .padding(.horizontal, 15.0)
        .padding(.vertical, 10.0)
        .background(Color.background)
      }
    } destination: { pathStore in
      switch pathStore.state {
      case .newPlanStep(let step):
        if let newPlanStore = store.scope(
          state: \.newPlan,
          action: \.newPlan
        ) {
          NewPlanView(
            store: newPlanStore,
            presentationContext: .onboarding(step)
          )
        }
      case .templateSelection:
        if let templateStore = pathStore.scope(
          state: \.templateSelection,
          action: \.templateSelection
        ) {
          OnboardingTemplateSelectionView(store: templateStore)
        }
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 5.0) {
      Text("What is your goal?", bundle: .module)
        .font(.largeTitle.bold())
        .foregroundStyle(Color.primaryText)

      Text(
        "Pick a starting point and build a plan around it with SnapDay",
        bundle: .module
      )
      .font(.subheadline)
      .foregroundStyle(Color.secondaryText)
    }
    .padding(.bottom, 10.0)
  }

  private func goalOptions(_ goals: [OnboardingGoal]) -> some View {
    VStack(spacing: 5.0) {
      ForEach(goals) { goal in
        goalOption(goal)
      }
    }
  }

  private func goalOption(_ goal: OnboardingGoal) -> some View {
    let isSelected = store.selectedGoal == goal

    return Button(
      action: { store.send(.view(.goalTapped(goal))) },
      label: {
        HStack(spacing: 10.0) {
          goalIcon(goal)
            .frame(width: 35.0)

          VStack(alignment: .leading, spacing: 5.0) {
            Text(goal.title)
              .font(.callout.weight(.semibold))
              .foregroundStyle(Color.primaryText)

            Text(goal.subtitle)
              .font(.footnote)
              .foregroundStyle(Color.secondaryText)
              .lineLimit(2)
          }

          Spacer(minLength: .zero)
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 15.0)
        .frame(maxWidth: .infinity, minHeight: 70.0, alignment: .leading)
        .background(Color.formBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8.0))
        .overlay {
          RoundedRectangle(cornerRadius: 8.0)
            .stroke(isSelected ? Color.actionBlue : Color.border, lineWidth: isSelected ? 1.5 : 1.0)
        }
        .contentShape(Rectangle())
      }
    )
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  @ViewBuilder
  private func goalIcon(_ goal: OnboardingGoal) -> some View {
    switch goal {
    case .readMore:
      Text("📖")
    case .moveMore:
      Text("🏃")
    case .healthyHabit:
      Text("🥗")
    case .learnSomething:
      Text("✍️")
    case .createMyOwn:
      Image(systemName: "plus")
    case .organizeMyDay:
      Image(systemName: "square.grid.3x3")
    }
  }
}
