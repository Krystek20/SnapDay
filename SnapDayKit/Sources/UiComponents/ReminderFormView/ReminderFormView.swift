import SwiftUI

public struct ReminderFormView: View {

  // MARK: - Properties

  private let title: String
  private let availableDateHours: ClosedRange<Date>
  private let toggleBinding: Binding<Bool>
  private let dateBinding: Binding<Date?>

  // MARK: - Initialization

  public init(
    title: String,
    availableDateHours: ClosedRange<Date>,
    toggleBinding: Binding<Bool>,
    dateBinding: Binding<Date?>
  ) {
    self.title = title
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
        Text(title)
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
