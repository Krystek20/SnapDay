import Foundation

struct URLProvider {
  static func url(for path: String) throws -> URL {
    var urlComponents = URLComponents()
    #if DEBUG
    urlComponents.host = "127.0.0.1"
    urlComponents.port = 8080
    #else
    urlComponents.scheme = "https"
    urlComponents.host = "snapday-server.onrender.com"
    #endif
    urlComponents.path = path

    guard let url = urlComponents.url else {
      throw URLErrorCode.badURL
    }
    return url
  }
}
