import SwiftUI
import ComposableArchitecture
import Resources
import Models
import UiComponents
import DayActivityForm

public struct ActivityListView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<ActivityListFeature>
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
    WithPerceptionTracking {
      content
        .activityBackground
        .navigationTitle(String(localized: "Template List", bundle: .module))
        .searchable(
          text: $store.searchText,
          placement: .navigationBarDrawer(displayMode: .always),
          prompt: String(localized: "Search for Activity", bundle: .module)
        )
        .onAppear {
          store.send(.view(.appeared))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
              Button(
                action: {
                  store.send(.view(.newButtonTapped))
                },
                label: {
                  Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.actionBlue)
                }
              )
            }
        }
        .sheet(item: $store.scope(state: \.templateForm, action: \.templateForm)) { store in
          NavigationStack {
            DayActivityFormView(store: store)
          }
          .presentationDetents([.large])
        }
    }
  }

  private var content: some View {
    WithPerceptionTracking {
      VStack(spacing: 15.0) {
        ScrollView {
          activitySection
          .padding(.bottom, 15.0)
          .padding(.horizontal, 15.0)
        }
        .scrollIndicators(.hidden)

        addButton
          .padding(.bottom, 15.0)
          .padding(.horizontal, 15.0)
      }
    }
  }

  @ViewBuilder
  private var activitySection: some View {
    WithPerceptionTracking {
      if !store.displayedActivities.isEmpty {
        SectionView(
          name: String(localized: "Templates", bundle: .module),
          rightContent: { },
          content: { activityList }
        )
      }
    }
  }

  private var activityList: some View {
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        ForEach(store.displayedActivities) { activity in
          HStack(spacing: .zero) {
            if store.selectedActivities.contains(activity) {
              selectionIcon
            }
            activityRow(for: activity)
          }
          if activity.id != store.displayedActivities.last?.id {
            Divider()
          }
        }
      }
      .formBackgroundModifier(padding: EdgeInsets(.zero))
    }
  }

  private func activityRow(for activity: Activity) -> some View {
    WithPerceptionTracking {
      DayActivityRow(activity: activity, trailingIcon: .edit) {
        store.send(.view(.activityEditTapped(activity)))
      }
      .contentShape(Rectangle())
      .onTapGesture {
        store.send(.view(.activityTapped(activity)))
      }
    }
  }

  private var selectionIcon: some View {
    Image(systemName: "checkmark.circle.fill")
      .resizable()
      .scaledToFill()
      .fontWeight(.light)
      .frame(width: 20.0, height: 20.0)
      .foregroundStyle(Color.actionBlue)
      .padding(.leading, 10.0)
  }

  private var addButton: some View {
    WithPerceptionTracking {
      Button(
        action: { store.send(.view(.addButtonTapped)) },
        label: {
          Text("Add (\(store.selectedActivities.count))", bundle: .module)
        }
      )
      .disabled(store.selectedActivities.isEmpty)
      .buttonStyle(PrimaryButtonStyle(disabled: store.selectedActivities.isEmpty))
    }
  }
}
