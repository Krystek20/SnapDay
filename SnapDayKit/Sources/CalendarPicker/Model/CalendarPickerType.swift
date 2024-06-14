import Foundation

public enum CalendarPickerConfirm: Equatable {
  case navigationButton(title: String)
  case noConfirmation
}

public enum CalendarPickerType: Equatable {
  case singleSelection(CalendarPickerConfirm)
  case multiSelection(title: String)
}
