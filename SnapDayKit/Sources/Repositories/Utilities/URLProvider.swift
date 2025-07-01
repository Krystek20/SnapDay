import Foundation

enum URLs {
//  static let host = "127.0.0.1"
  static let host = "369c-89-71-124-130.ngrok-free.app"
}

struct URLProvider {
  static func url(for path: String) throws -> URL {
    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    urlComponents.host = URLs.host
    urlComponents.path = path
//    urlComponents.port = 8080

    guard let url = urlComponents.url else {
      throw URLErrorCode.badURL
    }
    return url
  }
}
