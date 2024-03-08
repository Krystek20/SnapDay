import SwiftUI
import ComposableArchitecture
import Resources
import Models
import UiComponents
import ActivityForm

public struct ActivityListView: View {

  // MARK: - Properties

  private let store: StoreOf<ActivityListFeature>
  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil),
    GridItem(.flexible(), spacing: 15.0, alignment: nil)
  ]

  // MARK: - Initialization

  public init(store: StoreOf<ActivityListFeature>) {
    self.store = store
  }

  // MARK: - Views

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      content(viewStore: viewStore)
        .navigationTitle(String(localized: "Activity list", bundle: .module))
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button(String(localized: "New", bundle: .module)) {
              viewStore.send(.view(.newButtonTapped))
            }
            .font(.system(size: 12.0, weight: .bold))
            .foregroundStyle(Color.lavenderBliss)
          }
        }
        .onAppear {
          viewStore.send(.view(.appeared))
        }
        .sheet(
          store: store.scope(
            state: \.$addActivity,
            action: { .addActivity($0) }
          ),
          content: { store in
            NavigationStack {
              ActivityFormView(store: store)
            }
            .presentationDetents([.large])
          }
        )
    }
  }

  private func content(viewStore: ViewStoreOf<ActivityListFeature>) -> some View {
    VStack(spacing: .zero) {
      activityList(viewStore: viewStore)
        .padding(.bottom, 15.0)
      addButton(viewStore: viewStore)
        .padding(.bottom, 15.0)
        .padding(.horizontal, 15.0)
    }
    .activityBackground
  }

  private func activityList(viewStore: ViewStoreOf<ActivityListFeature>) -> some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 15.0) {
        ForEach(viewStore.activities) { activity in
          ZStack {
            activityBackground(activity, viewStore: viewStore)
            activityView(activity, viewStore: viewStore)
          }
        }
      }
      .padding(.horizontal, 15.0)
    }
    .scrollIndicators(.hidden)
  }

  private func activityView(_ activity: Activity, viewStore: ViewStoreOf<ActivityListFeature>) -> some View {
    VStack(spacing: 5.0) {
      ActivityImageView(data: activity.image, size: 50.0, cornerRadius: 25.0)
      Text(activity.name)
        .multilineTextAlignment(.center)
        .font(.system(size: 16.0, weight: .bold))
        .foregroundStyle(Color.slateHaze)
    }
    .padding(5.0)
    .contentShape(Rectangle())
    .onTapGesture {
      viewStore.send(.view(.activityTapped(activity)))
    }
    .contextMenu {
      Button(
        action: {
          viewStore.send(.view(.activityEditTapped(activity)))
        },
        label: {
          Text("Edit", bundle: .module)
          Image(systemName: "pencil.circle")
        }
      )
    }
  }

  @ViewBuilder
  private func activityBackground(_ activity: Activity, viewStore: ViewStoreOf<ActivityListFeature>) -> some View {
    viewStore.selectedActivities.contains(activity)
    ? AnyView(
      Color.pureWhite
        .clipShape(RoundedRectangle(cornerRadius: 10.0))
    )
    : AnyView(Color.grayLight)
  }

  private func addButton(viewStore: ViewStoreOf<ActivityListFeature>) -> some View {
    Button(
      action: { viewStore.send(.view(.addButtonTapped)) },
      label: {
        Text("Add (\(viewStore.selectedActivities.count))", bundle: .module)
      }
    )
    .disabled(viewStore.selectedActivities.isEmpty)
    .buttonStyle(PrimaryButtonStyle(disabled: viewStore.selectedActivities.isEmpty))
  }
}
