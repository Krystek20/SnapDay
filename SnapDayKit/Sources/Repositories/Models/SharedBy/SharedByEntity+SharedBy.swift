import Models

extension SharedByEntity {
  func setup(by sharedBy: SharedBy) {
    identifier = sharedBy.identifier
    userIdentifier = sharedBy.userId
    objectIdentifier = sharedBy.objectId
  }
}
