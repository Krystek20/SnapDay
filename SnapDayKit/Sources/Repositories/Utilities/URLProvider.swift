import Foundation

public struct URLProvider {

  public static var host: String {
    UserDefaults.standard.bool(forKey: "isTestingHost")
    ? "relieved-manatee-wildly.ngrok-free.app"
    : "snapday-server.onrender.com"
  }

  public static func url(for path: String, isWebSocket: Bool = false) throws -> URL {
    var urlComponents = URLComponents()
    #if DEBUG || BETA
    urlComponents.host = "relieved-manatee-wildly.ngrok-free.app"
    #else
    urlComponents.host = host
    #endif
    urlComponents.scheme = isWebSocket ? "wss" : "https"
    urlComponents.path = path

    guard let url = urlComponents.url else {
      throw URLErrorCode.badURL
    }
    return url
  }
}
