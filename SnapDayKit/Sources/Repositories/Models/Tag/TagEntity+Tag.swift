import Models

extension TagEntity {
  func setup(by tag: Tag) {
    identifier = tag.id
    name = tag.name
  }
}
