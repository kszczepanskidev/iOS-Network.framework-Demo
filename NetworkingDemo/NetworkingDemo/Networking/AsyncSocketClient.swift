//
//  AsyncSocketClient.swift
//  NetworkingDemo
//
//  Created by Kamil Szczepański on 23/10/2018.
//  Copyright © 2018 Netguru. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

final class AsyncSocketClient {

    private let queue = DispatchQueue(label: "AsyncSocket Client Queue")

    var socket: GCDAsyncUdpSocket!

    init(delegate: GCDAsyncUdpSocketDelegate) {
        socket = GCDAsyncUdpSocket(delegate: delegate, delegateQueue: queue)
    }

    func start() {
        do {
            try socket.bind(toPort: UInt16(50011))

            let initialMsg = "Initial message"
            guard let data = initialMsg.data(using: .utf8) else { return }
            socket.send(data, toHost: "localhost", port: UInt16(50010), withTimeout: 2, tag: 0)

            try socket.beginReceiving()
        } catch {
            print("#ERROR start socket: \(error.localizedDescription)")
        }
    }
}
