import ActivityList
import ComposableArchitecture
import Resources
import SwiftUI
import UiComponents

@MainActor
public struct NewPlanView: View {

  // MARK: - Properties

  @Bindable private var store: StoreOf<NewPlanFeature>

  // MARK: - Initialization

  public init(store: StoreOf<NewPlanFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    NavigationStack(path: navigationPath) {
      stepView(for: .details)
        .navigationDestination(for: NewPlanStep.self) { step in
          stepView(for: step)
        }
    }
    .sheet(item: $store.scope(state: \.activityPicker, action: \.activityPicker)) { store in
      NavigationStack {
        ActivityListView(store: store)
      }
        .presentationDetents([.medium, .large])
    }
    .sheet(item: applySourceDayBinding) { weekday in
      ApplyToDaysView(store: store, sourceWeekday: weekday)
        .presentationDetents([.large])
    }
  }

  private func stepView(for step: NewPlanStep) -> some View {
    Group {
      switch step {
      case .details:
        NewPlanDetailsView(store: store)
      case .weeklySchedule:
        WeeklyScheduleView(store: store)
      case .review:
        NewPlanReviewView(store: store)
      }
    }
    .background
    .navigationTitle(navigationTitle(for: step))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        if step == .details {
          Button(
            action: { store.send(.view(.cancelButtonTapped)) },
            label: { Text("Cancel", bundle: .module) }
          )
          .foregroundStyle(Color.actionBlue)
        }
      }
    }
    .safeAreaInset(edge: .bottom) {
      bottomAction(for: step)
    }
  }

  private var navigationPath: Binding<[NewPlanStep]> {
    Binding(
      get: {
        switch store.step {
        case .details:
          []
        case .weeklySchedule:
          [.weeklySchedule]
        case .review:
          [.weeklySchedule, .review]
        }
      },
      set: { path in
        store.send(.view(.navigationPathChanged(path)))
      }
    )
  }

  private func navigationTitle(for step: NewPlanStep) -> String {
    switch step {
    case .details:
      String(localized: "New Plan", bundle: .module)
    case .weeklySchedule:
      String(localized: "Weekly Schedule", bundle: .module)
    case .review:
      String(localized: "Review Plan", bundle: .module)
    }
  }

  @ViewBuilder
  private func bottomAction(for step: NewPlanStep) -> some View {
    switch step {
    case .details:
      actionButton(title: String(localized: "Continue", bundle: .module)) {
        store.send(.view(.continueButtonTapped))
      }
      .disabled(!store.canContinue)
    case .weeklySchedule:
      actionButton(title: String(localized: "Review Plan", bundle: .module)) {
        store.send(.view(.continueButtonTapped))
      }
      .disabled(!store.canReview)
    case .review:
      actionButton(title: String(localized: "Start Plan", bundle: .module)) {
        store.send(.view(.startPlanButtonTapped))
      }
    }
  }

  private func actionButton(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
    }
    .buttonStyle(PrimaryButtonStyle())
    .padding(.horizontal, 15.0)
    .padding(.vertical, 10.0)
    .background(Color.background)
  }

  private var applySourceDayBinding: Binding<PlanWeekday?> {
    Binding(
      get: { store.applySourceDay },
      set: { value in
        if value == nil {
          store.send(.view(.applyCancelled))
        }
      }
    )
  }
}

@MainActor
private struct NewPlanDetailsView: View {

  @Bindable var store: StoreOf<NewPlanFeature>
  @FocusState private var isNameFocused: Bool

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 15.0) {
        nameSection
        durationSection
        dateRangeSection
      }
      .padding(15.0)
    }
    .scrollDismissesKeyboard(.immediately)
    .scrollIndicators(.hidden)
  }

  private var nameSection: some View {
    NewPlanSection(title: String(localized: "PLAN NAME", bundle: .module)) {
      HStack(spacing: 10.0) {
        Text("Name", bundle: .module)
          .foregroundStyle(Color.primaryText)

        Spacer(minLength: 10.0)

        TextField(
          String(localized: "Learn Spanish", bundle: .module),
          text: $store.name
        )
        .foregroundStyle(Color.primaryText)
        .multilineTextAlignment(.trailing)
        .textInputAutocapitalization(.words)
        .submitLabel(.done)
        .focused($isNameFocused)
        .onSubmit {
          isNameFocused = false
        }
      }
      .font(.system(size: 15.0, weight: .regular))
      .padding(.horizontal, 15.0)
      .frame(minHeight: 55.0)
      .contentShape(Rectangle())
      .onTapGesture {
        isNameFocused = true
      }
      .background(
        Color.formBackground
          .clipShape(RoundedRectangle(cornerRadius: 14.0))
      )
    }
  }

  private var durationSection: some View {
    NewPlanSection(title: String(localized: "HOW LONG", bundle: .module)) {
      DurationFlowLayout(spacing: 10.0) {
        ForEach(PlanDuration.allCases) { duration in
          DurationChip(
            title: String(localized: duration.title, bundle: .module),
            isSelected: store.selectedDuration == duration,
            action: { store.send(.view(.durationTapped(duration))) }
          )
        }
      }
      .padding(15.0)
      .background(
        Color.formBackground
          .clipShape(RoundedRectangle(cornerRadius: 14.0))
      )
    }
  }

  private var dateRangeSection: some View {
    NewPlanSection(title: String(localized: "DATE RANGE", bundle: .module)) {
      VStack(spacing: .zero) {
        datePicker(
          title: String(localized: "Starts", bundle: .module),
          selection: $store.startDate,
          range: Date.distantPast...Date.distantFuture
        )

        Divider()
          .padding(.horizontal, 15.0)

        datePicker(
          title: String(localized: "Ends", bundle: .module),
          selection: $store.endDate,
          range: store.startDate...Date.distantFuture
        )
        .allowsHitTesting(store.selectedDuration == .custom)
      }
      .background(
        Color.formBackground
          .clipShape(RoundedRectangle(cornerRadius: 14.0))
      )

      Text("Preset duration keeps the same length when start date changes. Custom lets you choose the end date.", bundle: .module)
        .font(.system(size: 13.0, weight: .regular))
        .foregroundStyle(Color.sectionText)
        .lineSpacing(2.0)
        .padding(.horizontal, 10.0)
        .padding(.top, 5.0)
    }
  }

  private func datePicker(
    title: String,
    selection: Binding<Date>,
    range: ClosedRange<Date>
  ) -> some View {
    DatePicker(
      selection: selection,
      in: range,
      displayedComponents: .date,
      label: {
        Text(title)
          .font(.system(size: 15.0, weight: .regular))
          .foregroundStyle(Color.primaryText)
      }
    )
    .datePickerStyle(.compact)
    .tint(Color.actionBlue)
    .padding(.horizontal, 15.0)
    .frame(minHeight: 55.0)
  }
}

struct NewPlanSection<Content: View>: View {

  let title: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 10.0) {
      Text(title)
        .font(.system(size: 13.0, weight: .regular))
        .foregroundStyle(Color.sectionText)
        .padding(.leading, 5.0)

      content()
    }
  }
}

private struct DurationChip: View {

  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 14.0, weight: .semibold))
        .foregroundStyle(isSelected ? Color.pureWhite : Color.primaryText)
        .lineLimit(1)
        .padding(.horizontal, 15.0)
        .frame(height: 36.0)
        .background(
          (isSelected ? Color.actionBlue : Color.emphasisBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10.0))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 10.0)
            .stroke(isSelected ? Color.clear : Color.border, lineWidth: 1.0)
        )
    }
    .buttonStyle(.plain)
  }
}

private struct DurationFlowLayout: Layout {

  let spacing: CGFloat

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    let result = layout(subviews: subviews, width: proposal.width ?? .infinity)
    return CGSize(width: proposal.width ?? result.width, height: result.height)
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    var position = CGPoint(x: bounds.minX, y: bounds.minY)
    var rowHeight: CGFloat = .zero

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if position.x > bounds.minX, position.x + size.width > bounds.maxX {
        position.x = bounds.minX
        position.y += rowHeight + spacing
        rowHeight = .zero
      }

      subview.place(at: position, proposal: ProposedViewSize(size))
      position.x += size.width + spacing
      rowHeight = max(rowHeight, size.height)
    }
  }

  private func layout(subviews: Subviews, width: CGFloat) -> CGSize {
    var currentRowWidth: CGFloat = .zero
    var currentRowHeight: CGFloat = .zero
    var totalWidth: CGFloat = .zero
    var totalHeight: CGFloat = .zero

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      let proposedWidth = currentRowWidth == .zero
        ? size.width
        : currentRowWidth + spacing + size.width

      if proposedWidth > width, currentRowWidth > .zero {
        totalWidth = max(totalWidth, currentRowWidth)
        totalHeight += currentRowHeight + spacing
        currentRowWidth = size.width
        currentRowHeight = size.height
      } else {
        currentRowWidth = proposedWidth
        currentRowHeight = max(currentRowHeight, size.height)
      }
    }

    totalWidth = max(totalWidth, currentRowWidth)
    totalHeight += currentRowHeight
    return CGSize(width: totalWidth, height: totalHeight)
  }
}
