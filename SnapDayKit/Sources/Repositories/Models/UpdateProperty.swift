import Foundation

public enum UpdateProperty: Encodable {
  case date(old: Date?, new: Date?)
  case name(old: String, new: String)
  case dueDate(old: Date?, new: Date?)
  case important(Bool)
  case done(String)
  case undone(String)
  case taskAdded(String)
  case taskRemoved(String)
  case taskDone(String)
  case taskUndone(String)
  case taskNameChanged(old: String, new: String)
}
