import Foundation

struct URLProvider {
  static func url(for path: String) throws -> URL {
    var urlComponents = URLComponents()
    #if DEBUG
    urlComponents.host = "relieved-manatee-wildly.ngrok-free.app"
    #else
    urlComponents.host = "snapday-server.onrender.com"
    #endif
    urlComponents.scheme = "https"
    urlComponents.path = path

    guard let url = urlComponents.url else {
      throw URLErrorCode.badURL
    }
    return url
  }
}
