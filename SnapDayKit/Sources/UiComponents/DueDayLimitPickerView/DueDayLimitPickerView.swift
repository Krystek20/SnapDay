import SwiftUI
import Resources

public struct DueDayLimitPickerView: View {

  // MARK: - Properties

  @Binding private var selectedDaysCount: Int

  // MARK: - Initialization

  public init(selectedDaysCount: Binding<Int>) {
    self._selectedDaysCount = selectedDaysCount
  }

  // MARK: - Views

  public var body: some View {
    HStack(spacing: 5.0) {
      Menu {
        Picker(selection: $selectedDaysCount) {
          ForEach(0...14, id: \.self) { dayCount in
            if dayCount == 1 {
              Text(String(localized: "\(dayCount) day", bundle: .module)).tag(dayCount)
            } else {
              Text(String(localized: "\(dayCount) days", bundle: .module)).tag(dayCount)
            }
          }
        } label: { }
      } label: {
        daysLabelText
          .font(.system(size: 14.0, weight: .medium))
          .foregroundStyle(Color.standardText)
      }
      .id(String(selectedDaysCount))
    }
  }

  private var daysLabelText: Text {
    if selectedDaysCount == 1 {
      Text(String(localized: "\(selectedDaysCount) day", bundle: .module))
    } else {
      Text(String(localized: "\(selectedDaysCount) days", bundle: .module))
    }
  }
}
