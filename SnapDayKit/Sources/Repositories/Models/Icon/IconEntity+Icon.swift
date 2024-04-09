import Foundation
import Models
import CoreData

extension IconEntity {
  func setup(by icon: Icon) throws {
    identifier = icon.id
    data = icon.data
  }
}
