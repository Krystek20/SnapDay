import SwiftUI
import Resources

public struct DurationPickerView: View {

  // MARK: - Properties

  @Binding private var selectedHours: Int
  @Binding private var selectedMinutes: Int

  // MARK: - Initialization

  public init(selectedHours: Binding<Int>, selectedMinutes: Binding<Int>) {
    self._selectedHours = selectedHours
    self._selectedMinutes = selectedMinutes
  }

  // MARK: - Views

  public var body: some View {
    HStack(spacing: 5.0) {
      Menu {
        Picker(selection: $selectedHours) {
          ForEach(0..<24, id: \.self) { hour in
            Text(String(localized: "\(hour) hours", bundle: .module)).tag(hour)
          }
        } label: { }
      } label: {
        Text(String(localized: "\(selectedHours) hours", bundle: .module))
          .font(.system(size: 14.0, weight: .semibold))
          .foregroundStyle(Color.deepSpaceBlue)
      }
      .id(String(selectedHours))

      Menu {
        Picker(selection: $selectedMinutes) {
          ForEach(0..<60, id: \.self) { minute in
            Text(String(localized: "\(minute) min", bundle: .module)).tag(minute)
          }
        } label: { }
      } label: {
        Text(String(localized: "\(selectedMinutes) min", bundle: .module))
          .font(.system(size: 14.0, weight: .semibold))
          .foregroundStyle(Color.deepSpaceBlue)
      }
      .id(String(selectedMinutes))
    }
  }
}
