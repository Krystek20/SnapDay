import ComposableArchitecture
import SwiftUI
import Dashboard
import TimePeriodDetails
import Details
import Resources

public struct ApplicationView: View {

  // MARK: - Properties

  private let store: StoreOf<ApplicationFeature>

  // MARK: - Initialization

  public init(store: StoreOf<ApplicationFeature>) {
    self.store = store

    #warning("Move it")
    let appearance = UINavigationBarAppearance()
    appearance.backgroundColor = Colors.lightGray.color

    appearance.largeTitleTextAttributes = [
      .font: Fonts.Quicksand.bold.font(size: 28.0),
      .foregroundColor: Colors.deepSpaceBlue.color
    ]
    appearance.titleTextAttributes = [
      .font: Fonts.Quicksand.bold.font(size: 18.0),
      .foregroundColor: Colors.deepSpaceBlue.color
    ]

    let scrollEdgeAppearance = appearance.copy()
    scrollEdgeAppearance.shadowImage = nil
    scrollEdgeAppearance.shadowColor = nil

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
  }

  // MARK: - Views

  public var body: some View {
    NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
      DashboardView(
        store: store.scope(
          state: \.dashboard,
          action: { .dashboard($0) }
        )
      )
    } destination: { state in
      switch state {
      case .timePeriodDetails:
        CaseLet(
          /ApplicationFeature.Path.State.timePeriodDetails,
           action: ApplicationFeature.Path.Action.timePeriodDetails,
           then: TimePeriodDetailsView.init
        )
      case .details:
        CaseLet(
          /ApplicationFeature.Path.State.details,
           action: ApplicationFeature.Path.Action.details,
           then: DetailsView.init
        )
      }
    }
  }
}
