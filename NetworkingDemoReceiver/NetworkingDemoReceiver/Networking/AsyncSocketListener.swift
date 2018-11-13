//
//  AsyncSocketServer.swift
//  NetworkingDemoReceiver
//
//  Created by Kamil Szczepański on 23/10/2018.
//  Copyright © 2018 Netguru. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

final class AsyncSocketListener: NSObject {

    private let queue = DispatchQueue(label: "AsyncSocket Server Queue")

    private var socket: GCDAsyncUdpSocket!
    private var connectedAddresses = Set<Data>()

    override init() {
        super.init()
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: queue)
    }

    func start() {
        do {
            try socket.bind(toPort: UInt16(50010))
            try socket.enableBroadcast(true)
            try socket.enableReusePort(true)
            try socket.beginReceiving()
        } catch {
            print("#ERROR start socket: \(error.localizedDescription)")
        }
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(broadcast), userInfo: nil, repeats: true)
    }
    @objc func broadcast() {
        guard let data = "Broadcast message".data(using: .utf8) else { return }
        socket.send(data, toHost: "255.255.255.255", port: 50011, withTimeout: 2, tag: 0)
    }

    func send(_ frame: Data) {
        connectedAddresses.forEach {
            socket.send(frame, toAddress: $0, withTimeout: 2, tag: 0)
        }
    }
}

extension AsyncSocketListener: GCDAsyncUdpSocketDelegate {

    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        debugPrint("DEBUG received: \(String(data: data, encoding: .utf8) ?? "not a string")")
        connectedAddresses.insert(address)
    }
}
