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
        .maxWidth()
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
    ScrollView {
      activityList
        .padding(.bottom, 15.0)
        .padding(.horizontal, 15.0)
    }
    .scrollIndicators(.hidden)
  }

  private var activityList: some View {
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        informationViewIfNeeded
        newActivityFormIfNeeded
        ForEach(store.displayedActivities) { activity in
          activityView(for: activity)
          if activity.id != store.displayedActivities.last?.id {
            Divider()
          }
        }
      }
      .formBackgroundModifier(padding: EdgeInsets(.zero))
    }
  }

  @ViewBuilder
  private var informationViewIfNeeded: some View {
    WithPerceptionTracking {
      if let informationConfiguration = store.information {
        InformationView(configuration: informationConfiguration)
      }
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

  private func activityView(for activity: Activity) -> some View {
    DayActivityRow(
      activityItem: DayActivityItem(activityType: activity),
      trailingIcon: .customView(
        TrailingIcon.moreIcon
          .overlay {
            activityMenuView(activity: activity)
          }
      )
    )
  }

  private func activityMenuView(activity: Activity) -> some View {
    Menu {
      selectButton(activity: activity)
      editButton(activity: activity)
      enableButton(activity: activity)
      removeButton(activity: activity)
    } label: {
      Color.clear
        .frame(width: 30.0, height: 30.0)
    }
  }

  private func selectButton(activity: Activity) -> some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.addToDayButtonTapped(activity)))
        },
        label: {
          Text("Add to day", bundle: .module)
          Image(systemName: "plus.circle")
        }
      )
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

  private func enableButton(activity: Activity) -> some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.enableButtonTapped(activity)))
        },
        label: {
          if activity.isFrequentEnabled {
            Text("Disable Repeat", bundle: .module)
            Image(systemName: "repeat.circle.fill")
          } else {
            Text("Enable Repeat", bundle: .module)
            Image(systemName: "repeat.circle")
          }
        }
      )
    }
  }

  private func removeButton(activity: Activity) -> some View {
    WithPerceptionTracking {
      Button(
        action: {
          store.send(.view(.removeButtonTapped(activity)))
        },
        label: {
          Text("Remove", bundle: .module)
          Image(systemName: "trash")
        }
      )
    }
  }
}
