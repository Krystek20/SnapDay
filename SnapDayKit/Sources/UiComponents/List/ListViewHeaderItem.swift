import Foundation

public struct ListViewHeaderItem: Equatable {

  public struct ListViewHeaderAction: Equatable {
    let identifier: String
    let title: String.LocalizationValue

    public init(identifier: String, title: String.LocalizationValue) {
      self.identifier = identifier
      self.title = title
    }
  }

  let title: String.LocalizationValue
  let trailingAction: ListViewHeaderAction?

  public init(title: String.LocalizationValue, trailingAction: ListViewHeaderAction? = nil) {
    self.title = title
    self.trailingAction = trailingAction
  }
}
