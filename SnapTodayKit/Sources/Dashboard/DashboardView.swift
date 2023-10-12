import SwiftUI
import ComposableArchitecture
import UiComponents
import Resources

public struct DashboardView: View {

  // MARK: - Properties

  private let store: StoreOf<DashboardFeature>

  // MARK: - Initialization

  public init(store: StoreOf<DashboardFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack(alignment: .bottom) {
        ScrollView {
          headerView(userName: viewStore.userName)
            .padding(.horizontal, 10.0)
            .padding(.top, 15.0)
          SummaryView(activities: viewStore.activities)
            .padding(.top, 10.0)
          activitiesSection(viewStore: viewStore)
            .padding(.top, 10.0)
            .padding(.horizontal, 10.0)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, 15.0)
        addButton(viewStore: viewStore)
      }
    }
  }

  private func headerView(userName: String) -> some View {
    VStack(alignment: .leading, spacing: 2.0) {
      if !userName.isEmpty {
        Text("Hi \(userName),", bundle: .module)
          .font(Fonts.Quicksand.regular.swiftUIFont(size: 30.0))
          .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
      }
      Text("Welcome back 👋", bundle: .module)
        .font(Fonts.Quicksand.bold.swiftUIFont(size: 28.0))
        .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
    }
    .maxWidth()
  }

  private func activitiesSection(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    VStack(alignment: .leading, spacing: 10.0) {
      Text("Activities", bundle: .module)
        .font(Fonts.Quicksand.bold.swiftUIFont(size: 22.0))
        .foregroundStyle(Colors.deepSpaceBlue.swiftUIColor)
      OptionsView(
        options: viewStore.options,
        highlighted: viewStore.selectedOption,
        selected: { option in
          viewStore.send(.optionTapped(option))
        }
      )
      activitiesList(viewStore: viewStore)
        .padding(.vertical, 10.0)
    }
    .maxWidth()
  }

  private func activitiesList(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    LazyVStack(alignment: .leading, spacing: 15.0) {
      ForEach(viewStore.activities, content: ActivityView.init)
    }
    .maxWidth()
  }

  private func addButton(viewStore: ViewStoreOf<DashboardFeature>) -> some View {
    Button {
      viewStore.send(.startGameTapped)
    } label: {
      Image(systemName: "plus.circle.fill")
        .resizable()
        .fontWeight(.thin)
        .frame(width: 50.0, height: 50.0)
        .foregroundStyle(Colors.lavenderBliss.swiftUIColor)
    }
  }
}
