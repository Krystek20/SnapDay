public struct ListViewHeaderItem: Equatable {

  public struct ListViewHeaderAction: Equatable {
    let identifier: String
    let title: String

    public init(identifier: String, title: String) {
      self.identifier = identifier
      self.title = title
    }
  }

  let title: String
  let trailingAction: ListViewHeaderAction?

  public init(title: String, trailingAction: ListViewHeaderAction? = nil) {
    self.title = title
    self.trailingAction = trailingAction
  }
}
