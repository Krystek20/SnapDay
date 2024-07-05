import SwiftUI

public struct DateFormView: View {

  public struct Configuration {
    let title: String
    let label: String
    let components: DatePicker<Text>.Components
    let range: PartialRangeFrom<Date>?

    public init(
      title: String,
      label: String,
      components: DatePicker<Text>.Components,
      range: PartialRangeFrom<Date>? = nil
    ) {
      self.title = title
      self.label = label
      self.components = components
      self.range = range
    }
  }

  // MARK: - Properties

  private let configuration: Configuration
  private let toggleBinding: Binding<Bool>
  private let dateBinding: Binding<Date?>

  // MARK: - Initialization

  public init(
    configuration: Configuration,
    toggleBinding: Binding<Bool>,
    dateBinding: Binding<Date?>
  ) {
    self.configuration = configuration
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
        Text(configuration.title)
          .formTitleTextStyle
      }
      .toggleStyle(CheckToggleStyle())
      if let date = dateBinding.wrappedValue {
        datePicker(date: date)
      }
    }
  }

  private func datePicker(date: Date) -> DatePicker<some View> {
    if let range = configuration.range {
      DatePicker(
        selection: Binding(
          get: { date },
          set: { value in dateBinding.wrappedValue = value }
        ),
        in: range,
        displayedComponents: configuration.components,
        label: {
          Text(configuration.label)
            .formTitleTextStyle
        }
      )
    } else {
      DatePicker(
        selection: Binding(
          get: { date },
          set: { value in dateBinding.wrappedValue = value }
        ),
        displayedComponents: configuration.components,
        label: {
          Text(configuration.label)
            .formTitleTextStyle
        }
      )
    }
  }
}
