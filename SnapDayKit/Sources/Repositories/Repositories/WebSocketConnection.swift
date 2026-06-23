import Foundation
import Dependencies

public struct WebSocketConnection: Sendable, Equatable {
  let task: URLSessionWebSocketTask
}

public struct WebSocketClient {
  public var connect: @Sendable (_ url: URL) -> (WebSocketConnection, AsyncThrowingStream<Message, Error>)
  public var send: @Sendable (_ connection: WebSocketConnection, _ message: Message) async throws -> Void
  public var disconnect: @Sendable (_ connection: WebSocketConnection) async -> Void

  public enum Message: Equatable {
    case text(String)
    case data(Data)
  }
}

public extension DependencyValues {
  var webSocket: WebSocketClient {
    get { self[WebSocketClientKey.self] }
    set { self[WebSocketClientKey.self] = newValue }
  }
}

private enum WebSocketClientKey: DependencyKey {
  static let liveValue: WebSocketClient = .live()
}

extension WebSocketClient {
  static func live(session: URLSession = .shared) -> WebSocketClient {
    WebSocketClient(
      connect: { url in
        let task = session.webSocketTask(with: url)
        task.resume()

        let stream = AsyncThrowingStream<Message, Error> { continuation in
          func receive() {
            task.receive { result in
              switch result {
              case let .success(msg):
                switch msg {
                case let .string(text):
                  continuation.yield(.text(text))
                case let .data(data):
                  continuation.yield(.data(data))
                @unknown default: break
                }
                receive()
              case let .failure(error):
                continuation.finish(throwing: error)
              }
            }
          }
          receive()
          continuation.onTermination = { _ in
            task.cancel(with: .goingAway, reason: nil)
          }
        }
        return (WebSocketConnection(task: task), stream)
      },
      send: { connection, message in
        switch message {
        case let .text(text):
          try await connection.task.send(.string(text))
        case let .data(data):
          try await connection.task.send(.data(data))
        }
      },
      disconnect: { connection in
        connection.task.cancel(with: .normalClosure, reason: nil)
      }
    )
  }
}
