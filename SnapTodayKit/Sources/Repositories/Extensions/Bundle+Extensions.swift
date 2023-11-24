import Foundation

extension Bundle {
  func coreDataModelUrl(name: String) -> URL? {
    url(forResource: name, withExtension: .modelExtension)
  }
}

private extension String {
  static let modelExtension = ".momd"
}
