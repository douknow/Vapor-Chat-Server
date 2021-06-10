//
//  Response.swift
//  
//
//  Created by Xianzhao Han on 2021/6/10.
//

import Foundation


struct Response: Encodable {

    let status: Int
    let msg: String

    var json: String {
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            fatalError("Convert to json str fail")
        }
        return json
    }

}


extension Response {

    static let dataParseError: String = Response(status: 1, msg: "Data parse error").json
    static let successResponse: String = Response(status: 0, msg: "Send success").json

}

struct MessageResponse: Encodable {

    static func sendDestMessage(_ message: MessageData) -> String {
        MessageResponse(messageData: message).json
    }

    let status = 2
    let messageData: MessageData

    var json: String {
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return ""
        }
        return json
    }
}
