import SwiftUI
import ComposableArchitecture
import UiComponents
import Common
import Resources
import Models
import AppIntents
import Utilities

public struct WidgetActivityListView: View {

  // MARK: - Properties

  @Perception.Bindable private var store: StoreOf<WidgetActivityListFeature>
  private let listUpIntent: () -> any AppIntent
  private let listDownIntent: () -> any AppIntent
  private let switchItemIntent: (UUID) -> any AppIntent

  // MARK: - Initialization

  public init(
    store: StoreOf<WidgetActivityListFeature>,
    listUpIntent: @escaping () -> any AppIntent,
    listDownIntent: @escaping () -> any AppIntent,
    switchItemIntent: @escaping (UUID) -> any AppIntent
  ) {
    self.store = store
    self.listUpIntent = listUpIntent
    self.listDownIntent = listDownIntent
    self.switchItemIntent = switchItemIntent
  }

  // MARK: - Views

  public var body: some View {
    VStack(spacing: .zero) {
      headerView
      contentView
      bottomView
    }
    .formBackgroundModifier(padding: EdgeInsets(.zero))
  }

  private var headerView: some View {
    WithPerceptionTracking {
      HStack(spacing: 10.0) {
        if !store.isButtonSectionShown {
          Spacer()
        }

        Text(store.title)
          .font(.system(size: 14.0, weight: .regular))
          .foregroundStyle(Color.standardText)

        Spacer()
        
        if store.isButtonSectionShown {
          buttonSection
        }
      }
      .padding(.horizontal, 10.0)
      .frame(height: 50.0)
      .background(
        Color
          .formBackground
          .shadow(color: Color.standardText.opacity(0.15), radius: 5.0, x: .zero, y: .zero)
      )
    }
  }

  @ViewBuilder
  private var buttonSection: some View {
    if #available(iOS 17.0, *) {
      HStack(spacing: 10.0) {
        Button(intent: listUpIntent()) {
          Image(systemName: "chevron.up.circle.fill")
            .resizable()
            .foregroundStyle(
              Color.actionBlue.opacity(store.isUpButtonDisabled ? 0.3 : 1.0)
            )
            .frame(width: 20.0, height: 20.0)
        }
        .buttonStyle(.plain)
        .disabled(store.isUpButtonDisabled)

        Button(intent: listDownIntent()) {
          Image(systemName: "chevron.down.circle.fill")
            .resizable()
            .foregroundStyle(
              Color.actionBlue.opacity(store.isDownButtonDisabled ? 0.3 : 1.0)
            )
            .frame(width: 20.0, height: 20.0)
        }
        .buttonStyle(.plain)
        .disabled(store.isDownButtonDisabled)

        Link(destination: DeeplinkService.addActivity, label: {
          Image(systemName: "plus.circle.fill")
            .resizable()
            .foregroundStyle(Color.actionBlue)
            .frame(width: 20.0, height: 20.0)
        })
      }
    }
  }

  private var contentView: some View {
    WithPerceptionTracking {
      switch store.contentType {
      case .list(let dayActivityItems):
        listView(dayActivityItems: dayActivityItems)
      case .success:
        successView
      case .empty:
        emptyView
      }
    }
  }

  private var successView: some View {
    VStack(spacing: .zero) {
      Text("🎉 Great job! Now, take a rest and enjoy the rest of your day with a smile! 🎉", bundle: .module)
        .font(.system(size: 14.0, weight: .regular))
        .foregroundStyle(Color.standardText)
        .multilineTextAlignment(.center)
        .padding(.top, 20.0)
        .padding(.horizontal, 30.0)
      Spacer(minLength: .zero)
      Image("widget_success", bundle: .module)
        .resizable()
        .scaledToFit()
      Spacer(minLength: .zero)
    }
  }

  private var emptyView: some View {
    VStack(spacing: .zero) {
      Text("Your Day, Your Way", bundle: .module)
        .font(.system(size: 14.0, weight: .medium))
        .foregroundStyle(Color.standardText)
      Text("A blank canvas awaits your plans or spontaneous joys.", bundle: .module)
        .font(.system(size: 12.0, weight: .regular))
        .foregroundStyle(Color.standardText)
        .multilineTextAlignment(.center)
      Spacer(minLength: .zero)
      Image("widget_empty", bundle: .module)
        .resizable()
        .scaledToFit()
      Spacer(minLength: .zero)
      Link(destination: DeeplinkService.addActivity, label: {
        Text("Add Activity", bundle: .module)
          .font(.system(size: 14.0, weight: .semibold))
          .foregroundStyle(Color.pureWhite)
          .frame(height: 40.0)
          .maxWidth(alignment: .bottom)
          .tint(Color.actionBlue)
          .background(
            Color.actionBlue
              .clipShape(RoundedRectangle(cornerRadius: 10.0))
          )
      })
    }
    .padding(.all, 20.0)
  }

  private func listView(dayActivityItems: [DayActivityItem]) -> some View {
    VStack(spacing: .zero) {
      ForEach(dayActivityItems) { item in
        DayActivityRow(
          activityItem: item,
          size: .small,
          trailingIcon: .customView(customView(item: item))
        )
        .padding(.leading, item.isSubtask ? 10.0 : .zero)
        if item != dayActivityItems.last {
          Divider()
            .padding(.leading, item.isSubtask ? 10.0 : .zero)
        }
      }
      Spacer(minLength: .zero)
    }
    .padding(.top, 5.0)
  }

  @ViewBuilder
  private var bottomView: some View {
    WithPerceptionTracking {
      if let completedActivities = store.completedActivities {
        CompletedActivitiesView(
          completedActivities: completedActivities
        )
      }
    }
  }

  @ViewBuilder
  private func customView(item: DayActivityItem) -> some View {
    if #available(iOS 17.0, *) {
      Toggle(
        isOn: item.isStrikethrough,
        intent: switchItemIntent(item.id)
      ) {
        EmptyView()
      }
      .toggleStyle(CheckToggleStyle(showLabel: false))
    } else {
      EmptyView()
    }
  }
}
