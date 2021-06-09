import Fluent
import Vapor


struct User {
    let id: Int
    let username: String
}

let users = [
    User(id: 0, username: "Anna"),
    User(id: 1, username: "Bob")
]

func findUser(by id: Int) -> User? {
    users.first(where: { $0.id == id })
}

extension User: Equatable {
    static func ==(lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

var wss: [Int: WebSocket] = [:]

let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    return decoder
}()

let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    return encoder
}()

let queue = DispatchQueue(label: "com.websocket.write.wss")

func removeUserFromWss(user: User) {
    queue.sync(flags: .barrier) {
        _ = wss.removeValue(forKey: user.id)
    }
}

func saveUserAndSocket(user: User, ws: WebSocket) {
    queue.sync(flags: .barrier) {
        wss[user.id] = ws
    }
}

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    app.webSocket("echo") { req, ws in
        print("Connected")

        ws.onText { ws, content in
            print(content)
            ws.send(content)
        }
    }

    app.webSocket("chat") { req, ws in
        guard let query = try? req.query.decode(ChatQuery.self),
              let user = findUser(by: query.id) else {
            _ = ws.close(code: .unacceptableData)
            return
        }

        saveUserAndSocket(user: user, ws: ws)

        ws.onClose
            .whenSuccess({
                removeUserFromWss(user: user)
            })

        ws.onText { ws, text in
            guard let data = text.data(using: .utf8) else {
                ws.send(Response.dataParseError)
                return
            }

            do {
                let message = try decoder.decode(Message.self, from: data)

                if let destUser = findUser(by: message.to),
                   let destWs = wss[destUser.id] {
                    destWs.send(message.content)
                    ws.send(Response.successResponse)
                }
            } catch {
                print(error)
            }
        }

        print("Welcome to connect to chat: \(user.username)")
    }

    try app.register(collection: TodoController())
}

struct ChatQuery: Codable {
    let id: Int
}

struct Message: Codable {
    var time: Date! = Date()

    let to: Int
    let content: String
}

struct Response: Codable {
    let status: Int
    let msg: String

    var json: String {
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return "{ status: 1, msg: \"Response to json error.\" }"
        }
        return json
    }

    static let dataParseError: String = Response(status: 1, msg: "Data parse error").json
    static let successResponse: String = Response(status: 0, msg: "Send success").json
}

