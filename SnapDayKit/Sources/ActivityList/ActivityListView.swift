import SwiftUI
import ComposableArchitecture
import Resources
import Models
import UiComponents
import DayActivityForm

struct ActivityPlaceholder: ActivityType, Equatable {
  var id: UUID
  var name: String
  var icon: Icon? = nil
  var doneDate: Date? = nil
  var duration: Int = .zero
  var overview: String? = nil
  var reminderDate: Date? = nil
}

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
        .searchable(text: $store.searchText, prompt: String(localized: "Add or Search for Activity", bundle: .module))
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
        .sheet(item: $store.scope(state: \.templateForm, action: \.templateForm)) { store in
          NavigationStack {
            DayActivityFormView(store: store)
          }
          .presentationDetents([.large])
        }
        .sheet(item: $store.scope(state: \.dayActivityForm, action: \.dayActivityForm)) { store in
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
          VStack(spacing: .zero) {
            addNewActivity
              .padding(.bottom, 15.0)
            activitySection
              .padding(.bottom, 15.0)
            dayActivitySection
              .padding(.bottom, 15.0)
          }
          .padding(.horizontal, 15.0)
        }
        .scrollIndicators(.hidden)
        if store.showButton {
          addButton
            .padding(.bottom, 15.0)
            .padding(.horizontal, 15.0)
        }
      }
    }
  }

  @ViewBuilder
  private var addNewActivity: some View {
    WithPerceptionTracking {
      if store.activityPlaceholder != nil || !store.displayedNewDayActivities.isEmpty {
        SectionView(
          name: String(localized: "Add New", bundle: .module),
          rightContent: { },
          content: { newActivityList }
        )
      }
    }
  }

  private var newActivityList: some View {
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        if let activityPlaceholder = store.activityPlaceholder {
          DayActivityRow(activity: activityPlaceholder, trailingIcon: .none)
            .formBackgroundModifier(padding: EdgeInsets(.zero))
            .contentShape(Rectangle())
            .onTapGesture {
              store.send(.view(.activityPlaceholderTapped))
            }
          if !store.displayedNewDayActivities.isEmpty {
            Divider()
          }
        }

        ForEach(store.displayedNewDayActivities) { newDayActivity in
          newDayActivityRow(for: newDayActivity)
          if newDayActivity.id != store.displayedNewDayActivities.last?.id {
            Divider()
          }
        }
      }
      .formBackgroundModifier(padding: EdgeInsets(.zero))
    }
  }

  private func newDayActivityRow(for newDayActivity: DayActivity) -> some View {
    WithPerceptionTracking {
      HStack(spacing: .zero) {
        selectionIcon
        DayActivityRow(activity: newDayActivity, trailingIcon: .edit) {
          store.send(.view(.dayActivityEditTapped(newDayActivity)))
        }
      }
      .contentShape(Rectangle())
      .onTapGesture {
        store.send(.view(.newDayActivityTapped(newDayActivity)))
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
          activityRow(for: activity)
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
      HStack(spacing: .zero) {
        if store.selectedActivities.contains(activity) {
          selectionIcon
        }
        if store.configuration.isActivityEditable {
          DayActivityRow(activity: activity, trailingIcon: .edit) {
            store.send(.view(.activityEditTapped(activity)))
          }
        } else {
          DayActivityRow(activity: activity, trailingIcon: .none)
        }
      }
      .contentShape(Rectangle())
      .onTapGesture {
        store.send(.view(.activityTapped(activity)))
      }
    }
  }

  @ViewBuilder
  private var dayActivitySection: some View {
    if !store.displayedDayActivities.isEmpty {
      WithPerceptionTracking {
        SectionView(
          name: String(localized: "Historical", bundle: .module),
          rightContent: { },
          content: { dayActivityList }
        )
      }
    }
  }

  private var dayActivityList: some View {
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        ForEach(store.displayedDayActivities) { dayActivity in
          dayActivityRow(for: dayActivity)
          if dayActivity.id != store.displayedDayActivities.last?.id {
            Divider()
          }
        }
      }
      .formBackgroundModifier(padding: EdgeInsets(.zero))
    }
  }

  private func dayActivityRow(for dayActivity: DayActivity) -> some View {
    WithPerceptionTracking {
      HStack(spacing: .zero) {
        if store.selectedDayActivities.contains(dayActivity) {
          selectionIcon
        }
        DayActivityRow(activity: dayActivity, trailingIcon: .edit) {
          store.send(.view(.dayActivityEditTapped(dayActivity)))
        }
      }
      .contentShape(Rectangle())
      .onTapGesture {
        store.send(.view(.dayActivityTapped(dayActivity)))
      }
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
          Text("Add (\(store.selectedItemCount))", bundle: .module)
        }
      )
      .disabled(store.selectedItemCount == .zero)
      .buttonStyle(PrimaryButtonStyle(disabled: store.selectedItemCount == .zero))
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
