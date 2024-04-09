import Foundation

enum EntityError: Error {
  case attributeNil(fileID: String = #fileID)
}
