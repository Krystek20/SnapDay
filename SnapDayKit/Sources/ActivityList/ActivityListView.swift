import SwiftUI
import ComposableArchitecture
import Resources
import Models
import UiComponents
import ActivityForm

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
        .navigationTitle(String(localized: "Activity list", bundle: .module))
        .toolbar {
          if store.configuration.isActivityEditable {
            ToolbarItem(placement: .topBarTrailing) {
              newButton
            }
          }
        }
        .onAppear {
          store.send(.view(.appeared))
        }
        .sheet(item: $store.scope(state: \.addActivity, action: \.addActivity)) { store in
          NavigationStack {
            ActivityFormView(store: store)
          }
          .presentationDetents([.large])
        }
    }
  }

  private var content: some View {
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        activityList
          .padding(.bottom, 15.0)
        if store.showButton {
          addButton
            .padding(.bottom, 15.0)
            .padding(.horizontal, 15.0)
        }
      }
      .activityBackground
    }
  }

  private var activityList: some View {
    ScrollView {
      WithPerceptionTracking {
        LazyVGrid(columns: columns, spacing: 15.0) {
          ForEach(store.activities) { activity in
            ZStack {
              activityBackground(activity)
              activityView(activity)
            }
          }
        }
        .padding(.horizontal, 15.0)
      }
      .scrollIndicators(.hidden)
    }
  }

  @ViewBuilder
  private func activityBackground(_ activity: Activity) -> some View {
    WithPerceptionTracking {
      if store.selectedActivities.contains(activity) {
        Color.formBackground
          .clipShape(RoundedRectangle(cornerRadius: 10.0))
      } else {
        Color.background
      }
    }
  }

  private func activityView(_ activity: Activity) -> some View {
    WithPerceptionTracking {
      VStack(spacing: 5.0) {
        ActivityImageView(
          data: activity.icon?.data,
          size: 50.0,
          cornerRadius: 25.0
        )
        Text(activity.name)
          .multilineTextAlignment(.center)
          .font(.system(size: 14.0, weight: .regular))
          .foregroundStyle(Color.standardText)
      }
      .padding(5.0)
      .contentShape(Rectangle())
      .onTapGesture {
        store.send(.view(.activityTapped(activity)))
      }
      .contextMenu {
        editButton(activity: activity)
      }
    }
  }

  private func editButton(activity: Activity) -> some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.activityEditTapped(activity)))
        },
        label: {
          Text("Edit", bundle: .module)
          Image(systemName: "pencil.circle")
        }
      )
    }
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

  private var newButton: some View {
    WithPerceptionTracking {
      Button(String(localized: "New", bundle: .module)) {
        store.send(.view(.newButtonTapped))
      }
      .font(.system(size: 12.0, weight: .bold))
      .foregroundStyle(Color.actionBlue)
    }
  }
}
