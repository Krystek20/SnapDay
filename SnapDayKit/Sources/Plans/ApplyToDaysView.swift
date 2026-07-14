import ComposableArchitecture
import Models
import Resources
import SwiftUI
import UiComponents

@MainActor
struct ApplyToDaysView: View {

  let store: StoreOf<NewPlanFeature>
  let sourceWeekday: PlanWeekday

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 15.0) {
          sourceSection
          targetSection

          Text("Selected days will use the source day's activities. Days with existing activities ask for confirmation.", bundle: .module)
            .font(.system(size: 13.0, weight: .regular))
            .foregroundStyle(Color.sectionText)
            .lineSpacing(2.0)
            .padding(.horizontal, 10.0)
        }
        .padding(15.0)
      }
      .scrollIndicators(.hidden)
      .background
      .navigationTitle(String(localized: "Apply to days", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(
            action: { store.send(.view(.applyCancelled)) },
            label: { Text("Cancel", bundle: .module) }
          )
          .foregroundStyle(Color.actionBlue)
        }
      }
      .safeAreaInset(edge: .bottom) {
        Button(
          action: { store.send(.view(.applyConfirmed)) },
          label: { Text(applyButtonTitle) }
        )
        .buttonStyle(PrimaryButtonStyle())
        .disabled(store.applyTargetDays.isEmpty)
        .padding(.horizontal, 15.0)
        .padding(.vertical, 10.0)
        .background(Color.background)
      }
      .confirmationDialog(
        String(localized: "Replace existing activities?", bundle: .module),
        isPresented: replacementConfirmationBinding,
        titleVisibility: .visible
      ) {
        Button(
          String(localized: "Replace activities", bundle: .module),
          role: .destructive,
          action: { store.send(.view(.replacementConfirmed)) }
        )
        Button(
          String(localized: "Cancel", bundle: .module),
          role: .cancel,
          action: { store.send(.view(.replacementCancelled)) }
        )
      } message: {
        Text("At least one selected day already has activities. Applying will replace them.", bundle: .module)
      }
    }
  }

  private var sourceSection: some View {
    NewPlanSection(title: String(localized: "SOURCE DAY", bundle: .module)) {
      VStack(alignment: .leading, spacing: 10.0) {
        Text(sourceWeekday.title)
          .font(.system(size: 16.0, weight: .semibold))
          .foregroundStyle(Color.primaryText)

        ScrollView(.horizontal) {
          HStack(spacing: 5.0) {
            ForEach(sourceActivities) { activity in
              Chip(title: activity.name)
            }
          }
        }
        .scrollIndicators(.hidden)
      }
      .padding(15.0)
      .background(
        Color.formBackground
          .clipShape(RoundedRectangle(cornerRadius: 14.0))
      )
    }
  }

  private var targetSection: some View {
    NewPlanSection(title: String(localized: "TARGET DAYS", bundle: .module)) {
      VStack(spacing: .zero) {
        ForEach(Array(targetDays.enumerated()), id: \.element.id) { index, day in
          Button {
            store.send(.view(.applyTargetTapped(day.weekday)))
          } label: {
            HStack(spacing: 10.0) {
              VStack(alignment: .leading, spacing: 5.0) {
                Text(day.weekday.title)
                  .font(.system(size: 15.0, weight: .regular))
                  .foregroundStyle(Color.primaryText)

                if !day.activities.isEmpty {
                  Text("Has existing activities", bundle: .module)
                    .font(.system(size: 12.0, weight: .regular))
                    .foregroundStyle(Color.secondaryText)
                }
              }

              Spacer(minLength: 10.0)

              Image(systemName: store.applyTargetDays.contains(day.weekday) ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20.0))
                .foregroundStyle(
                  store.applyTargetDays.contains(day.weekday)
                    ? Color.actionBlue
                    : Color.sectionText
                )
            }
            .padding(.horizontal, 15.0)
            .frame(minHeight: 55.0)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)

          if index < targetDays.count - 1 {
            Divider()
              .padding(.horizontal, 15.0)
          }
        }
      }
      .background(
        Color.formBackground
          .clipShape(RoundedRectangle(cornerRadius: 14.0))
      )
    }
  }

  private var sourceActivities: [Activity] {
    store.schedule.first(where: { $0.weekday == sourceWeekday })?.activities ?? []
  }

  private var targetDays: [ScheduledPlanDay] {
    store.schedule.filter { $0.weekday != sourceWeekday }
  }

  private var applyButtonTitle: String {
    if store.applyTargetDays.count == 1 {
      return String(localized: "Apply to 1 day", bundle: .module)
    }
    return String(localized: "Apply to \(store.applyTargetDays.count) days", bundle: .module)
  }

  private var replacementConfirmationBinding: Binding<Bool> {
    Binding(
      get: { store.needsReplacementConfirmation },
      set: { isPresented in
        if !isPresented {
          store.send(.view(.replacementCancelled))
        }
      }
    )
  }
}
