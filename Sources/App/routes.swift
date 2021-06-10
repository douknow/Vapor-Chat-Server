import Fluent
import Vapor


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
              let user = User.findUser(by: query.id) else {
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
                let message = try decoder.decode(MessageData.self, from: data)
                ws.send(Response.successResponse)

                if let destUser = User.findUser(by: message.to),
                   let destWs = wss[destUser.id] {
                    let promise = req.eventLoop.makePromise(of: Void.self)
                    destWs.send(MessageResponse.sendDestMessage(message), promise: promise)
                    promise.futureResult.whenComplete { result in
                        if case let .failure(error) = result {
                            print("Send to dest ws error: \(error)")
                        }
                    }
                }
            } catch {
                print(error)
            }
        }

        print("Welcome to connect to chat: \(user.username)")
    }

    try app.register(collection: TodoController())
}



