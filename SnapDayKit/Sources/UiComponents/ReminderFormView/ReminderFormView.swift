import SwiftUI

public struct ReminderFormView: View {

  // MARK: - Properties

  private let reminderDate: Date?
  private let availableDateHours: ClosedRange<Date>
  private let toggleBinding: Binding<Bool>
  private let dateBinding: Binding<Date?>

  // MARK: - Initialization

  public init(
    reminderDate: Date?,
    availableDateHours: ClosedRange<Date>,
    toggleBinding: Binding<Bool>,
    dateBinding: Binding<Date?>
  ) {
    self.reminderDate = reminderDate
    self.availableDateHours = availableDateHours
    self.toggleBinding = toggleBinding
    self.dateBinding = dateBinding
  }

  // MARK: - View

  public var body: some View {
    reminderView
      .formBackgroundModifier()
  }

  private var reminderView: some View {
    VStack(spacing: 5.0) {
      Toggle(isOn: toggleBinding) {
        Text("Reminder", bundle: .module)
          .formTitleTextStyle
      }
      .toggleStyle(CheckToggleStyle())
      if let date = dateBinding.wrappedValue {
        DatePicker(
          selection: Binding(
            get: { date },
            set: { value in dateBinding.wrappedValue = value }
          ),
          in: availableDateHours,
          displayedComponents: [.hourAndMinute],
          label: {
            Text("Set time", bundle: .module)
              .formTitleTextStyle
          }
        )
      }
    }
  }
}
