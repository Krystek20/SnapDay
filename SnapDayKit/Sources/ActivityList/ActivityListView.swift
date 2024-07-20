import SwiftUI
import ComposableArchitecture
import Resources
import Models
import UiComponents
import DayActivityForm

public struct ActivityListView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<ActivityListFeature>
  @FocusState private var focus: DayNewField?
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
        .navigationTitle(String(localized: "Saved Activities", bundle: .module))
        .searchable(
          text: $store.searchText,
          placement: .navigationBarDrawer(displayMode: .always),
          prompt: String(localized: "Search for Activity", bundle: .module)
        )
        .onAppear {
          store.send(.view(.appeared))
        }
        .bind($store.focus, to: $focus)
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
          activityList
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

  private var activityList: some View {
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        newActivityFormIfNeeded
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

  @ViewBuilder
  private var newActivityFormIfNeeded: some View {
    if store.newActivity.isFormVisible {
      VStack(spacing: .zero) {
        HStack(spacing: 5.0) {
          ActivityImageView(
            data: nil,
            size: 30.0,
            cornerRadius: 15.0
          )
          TextField("", text: $store.newActivity.name)
            .font(.system(size: 14.0, weight: .medium))
            .foregroundStyle(Color.sectionText)
            .submitLabel(.done)
            .focused($focus, equals: .activityName)
          Spacer()
          if !store.newActivity.name.isEmpty {
            Button(String(localized: "Cancel", bundle: .module), action: {
              store.send(.view(.newActivityActionPerformed(.dayActivity(.cancelled))))
            })
            .font(.system(size: 12.0, weight: .bold))
            .foregroundStyle(Color.actionBlue)
          }
        }
        .padding(.all, 10.0)
        if !store.displayedActivities.isEmpty {
          Divider()
        }
      }
      .onSubmit {
        store.send(.view(.newActivityActionPerformed(.dayActivity(.submitted))))
      }
    }
  }


  private func activityRow(for activity: Activity) -> some View {
    WithPerceptionTracking {
      DayActivityRow(activity: activity, trailingIcon: .more) {
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
