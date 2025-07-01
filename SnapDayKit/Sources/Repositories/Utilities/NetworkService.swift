import Foundation
import Dependencies

extension DependencyValues {
  var networkService: NetworkService {
    get { self[NetworkService.self] }
    set { self[NetworkService.self] = newValue }
  }
}

extension NetworkService: DependencyKey {
  static var liveValue: NetworkService {
    NetworkService()
  }
}

enum URLErrorCode: Error {
  case badURL
  case badServerResponse
  case unexpectedStatusCode(Int)
}

enum HttpMethod: String {
  case post = "POST"
}

enum BodyType {
  case json(Encodable)
}

struct NetworkService {

  @discardableResult
  func request<T: Decodable>(
    url: URL,
    httpMethod: HttpMethod,
    body: BodyType? = nil,
    responseType: T.Type,
  ) async throws -> T {
    let data = try await request(
      url: url,
      httpMethod: httpMethod,
      body: body
    )
    return try JSONDecoder().decode(responseType, from: data)
  }

  @discardableResult
  func request(
    url: URL,
    httpMethod: HttpMethod,
    body: BodyType? = nil
  ) async throws -> Data {
    var request = URLRequest(url: url)
    request.httpMethod = httpMethod.rawValue

    switch body {
    case .json(let encodable):
      request.httpBody = try JSONEncoder().encode(encodable)
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    case nil:
      break
    }

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLErrorCode.badServerResponse
    }
    guard httpResponse.statusCode == 200 else {
      throw URLErrorCode.unexpectedStatusCode(httpResponse.statusCode)
    }

    return data
  }
}
