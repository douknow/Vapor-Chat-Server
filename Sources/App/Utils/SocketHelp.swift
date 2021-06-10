//
//  SocketHelp.swift
//  
//
//  Created by Xianzhao Han on 2021/6/10.
//

import Foundation
import Vapor


var wss: [Int: WebSocket] = [:]
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
