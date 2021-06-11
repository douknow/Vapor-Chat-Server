//
//  Response.swift
//  
//
//  Created by Xianzhao Han on 2021/6/10.
//

import Foundation


protocol Response: Encodable {
    var status: Int { get }
    var json: String { get }
}

extension Response {

    var json: String {
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            fatalError("Convert to json str fail")
        }
        return json
    }

}


struct InfoResponse: Response {
    let status: Int
    let msg: String
}


extension InfoResponse {
    static let dataParseError: String = InfoResponse(status: 1, msg: "Data parse error").json
    static let successResponse: String = InfoResponse(status: 0, msg: "Send success").json
}


func responseJSON(_ message: MessageData) -> String {
    switch message {
    case let message as TextMessageData:
        return MessageResponse(messageData: message).json
    case let message as ImgMessageData:
        return ImgResponse(messageData: message).json
    default:
        fatalError()
    }
}


struct MessageResponse: Response {
    let status = 2
    let messageData: TextMessageData
}


struct ImgResponse: Response {
    let status = 3
    let messageData: ImgMessageData
}
