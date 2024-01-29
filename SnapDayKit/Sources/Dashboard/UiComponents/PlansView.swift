import SwiftUI
import Resources
import Models
import UiComponents

struct PlansView: View {

  // MARK: - Properties

  let plans: [Plan]
  let planTapped: (Plan) -> Void
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]

  // MARK: - Views

  var body: some View {
    LazyVGrid(columns: columns, spacing: 15.0) {
      ForEach(plans, content: planView)
    }
  }

  private func planView(_ plan: Plan) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      Text(name(for: plan))
        .font(Fonts.Quicksand.bold.swiftUIFont(size: 16.0))
        .foregroundStyle(Colors.slateHaze.swiftUIColor)
      ProgressView(value: plan.completedValue) {
        Text("\(plan.percent)%")
          .font(Fonts.Quicksand.bold.swiftUIFont(size: 14.0))
          .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
      }
    }
    .formBackgroundModifier
    .onTapGesture {
      planTapped(plan)
    }
  }

  // MARK: - Private

  private func name(for plan: Plan) -> String {
    switch plan.type {
    case .daily:
      String(localized: "Daily", bundle: .module)
    case .weekly:
      String(localized: "Weekly", bundle: .module)
    case .monthly:
      String(localized: "Monthly", bundle: .module)
    case .quarterly:
      String(localized: "Quarterly", bundle: .module)
    case .custom:
      plan.name
    }
  }
}
