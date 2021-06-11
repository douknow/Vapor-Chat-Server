import Fluent
import Vapor


func routes(_ app: Application) throws {

    app.post("upload") { req -> EventLoopFuture<String> in
        let key = try req.query.get(String.self, at: "key")
        let path = req.application.directory.publicDirectory + key
        return req.body.collect()
            .unwrap(or: Abort(.noContent))
            .map {
                print($0)
                return $0
            }
            .flatMap { req.fileio.writeFile($0, at: path) }
            .map { key }
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
                ws.send(InfoResponse.dataParseError)
                return
            }

            let message: MessageData? = (try? decoder.decode(TextMessageData.self.self, from: data)) ??
                (try? decoder.decode(ImgMessageData.self, from: data))

            guard let message = message else {
                ws.send(InfoResponse.dataParseError)
                print("Invalid message data")
                return
            }

            ws.send(InfoResponse.successResponse)

            if let destUser = User.findUser(by: message.to),
               let destWs = wss[destUser.id] {
                let promise = req.eventLoop.makePromise(of: Void.self)
                destWs.send(responseJSON(message), promise: promise)
                promise.futureResult.whenComplete { result in
                    if case let .failure(error) = result {
                        print("Send to dest ws error: \(error)")
                    }
                }
            }
        }

        print("Welcome to connect to chat: \(user.username)")
    }

    try app.register(collection: TodoController())
}



