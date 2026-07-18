import ComposableArchitecture
import Resources
import SwiftUI

@MainActor
public struct PlanDetailsView: View {

  @Bindable private var store: StoreOf<PlanDetailsFeature>

  public init(store: StoreOf<PlanDetailsFeature>) {
    self.store = store
  }

  public var body: some View {
    Color.background
      .ignoresSafeArea()
      .navigationTitle(store.plan.name)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        if store.allowsManagement {
          ToolbarItem(placement: .topBarTrailing) {
            Button(
              action: { store.send(.view(.editButtonTapped)) },
              label: {
                Image(systemName: "pencil.circle.fill")
                  .accessibilityLabel(Text("Edit", bundle: .module))
              }
            )
            .foregroundStyle(Color.actionBlue)
          }

          ToolbarItem(placement: .topBarTrailing) {
            Menu {
              Button(
                role: .destructive,
                action: { store.send(.view(.archiveButtonTapped)) },
                label: { Text("Archive Plan", bundle: .module) }
              )
            } label: {
              Image(systemName: "ellipsis")
                .accessibilityLabel(Text("Plan actions", bundle: .module))
            }
            .foregroundStyle(Color.actionBlue)
          }
        }
      }
      .alert(
        String(localized: "Archive this Plan?", bundle: .module),
        isPresented: archiveConfirmationBinding
      ) {
        Button(
          String(localized: "Archive Plan", bundle: .module),
          role: .destructive,
          action: { store.send(.view(.archiveConfirmed)) }
        )
        Button(
          String(localized: "Cancel", bundle: .module),
          role: .cancel,
          action: { store.send(.view(.archiveCancelled)) }
        )
      } message: {
        Text("The Plan will move to History. Completed activities and progress will be kept.", bundle: .module)
      }
      .sheet(item: $store.scope(state: \.newPlan, action: \.newPlan)) { store in
        NewPlanView(store: store)
          .interactiveDismissDisabled()
      }
  }

  private var archiveConfirmationBinding: Binding<Bool> {
    Binding(
      get: { store.isArchiveConfirmationPresented },
      set: { isPresented in
        if !isPresented {
          store.send(.view(.archiveCancelled))
        }
      }
    )
  }
}
