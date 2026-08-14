import ComposableArchitecture
import Resources
import SwiftUI
import UiComponents

struct OnboardingTemplateSelectionView: View {

  let store: StoreOf<OnboardingTemplateSelectionFeature>

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 15.0) {
        header
        templates
        alternativeCopy
      }
      .padding(.horizontal, 15.0)
      .padding(.top, 10.0)
      .padding(.bottom, 15.0)
    }
    .scrollIndicators(.hidden)
    .background(Color.background)
    .navigationBarTitleDisplayMode(.inline)
    .safeAreaInset(edge: .bottom) {
      actions
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 5.0) {
      Text(store.category.title)
        .font(.largeTitle.bold())
        .foregroundStyle(Color.primaryText)

      Text(
        "Templates are just a fast start. You can rename and adjust the plan later.",
        bundle: .module
      )
      .font(.subheadline)
      .foregroundStyle(Color.secondaryText)
    }
  }

  private var templates: some View {
    VStack(spacing: 5.0) {
      ForEach(store.category.templates) { template in
        templateRow(template)
      }
    }
  }

  private func templateRow(_ template: OnboardingTemplate) -> some View {
    let isSelected = store.selectedTemplateID == template.id

    return Button {
      store.send(.view(.templateTapped(template.id)))
    } label: {
      HStack(spacing: 10.0) {
        Text(template.icon)
          .font(.title3)
          .frame(width: 35.0)

        VStack(alignment: .leading, spacing: 5.0) {
          Text(template.title)
            .font(.callout.weight(.semibold))
            .foregroundStyle(Color.primaryText)

          Text(template.subtitle)
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
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private var alternativeCopy: some View {
    VStack(alignment: .leading, spacing: 5.0) {
      Text("Not seeing your goal?", bundle: .module)
        .font(.footnote)
        .textCase(.uppercase)
        .foregroundStyle(Color.sectionText)

      Text("Create a plan from scratch or use the selected shortcut.", bundle: .module)
        .font(.callout.weight(.semibold))
        .foregroundStyle(Color.secondaryText)
    }
  }

  private var actions: some View {
    VStack(spacing: 10.0) {
      Button(
        String(localized: "Use this template", bundle: .module),
        action: { store.send(.view(.useTemplateTapped)) }
      )
      .buttonStyle(PrimaryButtonStyle())

      Button(
        String(localized: "Create your own", bundle: .module),
        action: { store.send(.view(.createOwnTapped)) }
      )
      .font(.system(size: 14.0, weight: .semibold))
      .foregroundStyle(Color.actionBlue)
      .frame(maxWidth: .infinity, minHeight: 40.0)
      .overlay {
        RoundedRectangle(cornerRadius: 14.0)
          .stroke(Color.actionBlue, lineWidth: 1.0)
      }
    }
    .padding(.horizontal, 15.0)
    .padding(.vertical, 10.0)
    .background(Color.background)
  }
}
