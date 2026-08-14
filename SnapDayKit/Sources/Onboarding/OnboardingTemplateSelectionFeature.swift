import ComposableArchitecture

@Reducer
public struct OnboardingTemplateSelectionFeature {

  @ObservableState
  public struct State: Equatable {
    let category: OnboardingTemplateCategory
    var selectedTemplateID: OnboardingTemplate.ID

    init(category: OnboardingTemplateCategory) {
      self.category = category
      self.selectedTemplateID = category.defaultTemplate.id
    }

    var selectedTemplate: OnboardingTemplate {
      category.templates.first { $0.id == selectedTemplateID } ?? category.defaultTemplate
    }
  }

  public enum Action: Equatable {
    public enum ViewAction: Equatable {
      case createOwnTapped
      case templateTapped(String)
      case useTemplateTapped
    }

    public enum DelegateAction: Equatable {
      case createPlanRequested(OnboardingPlanRequest)
    }

    case view(ViewAction)
    case delegate(DelegateAction)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(.templateTapped(let id)):
        guard state.category.templates.contains(where: { $0.id == id }) else { return .none }
        state.selectedTemplateID = id
        return .none
      case .view(.useTemplateTapped):
        return .send(.delegate(.createPlanRequested(state.selectedTemplate.planRequest)))
      case .view(.createOwnTapped):
        return .send(.delegate(.createPlanRequested(.empty)))
      case .delegate:
        return .none
      }
    }
  }
}
