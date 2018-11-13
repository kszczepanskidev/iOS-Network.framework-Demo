//
//  UDPClient.swift
//  NetworkingDemo
//
//  Created by Kamil Szczepański on 18/09/2018.
//  Copyright © 2018 Netguru. All rights reserved.
//

import Foundation
import Network

protocol VideoFrameReceiver: class {
    func receive(frame: Data)
}

final class UDPClient {

    weak var delegate: VideoFrameReceiver?

    private let connection: NWConnection
    private var sendErrorHandler: NWConnection.SendCompletion!
    private let queue = DispatchQueue(label: "UDP Client Queue")

    init() {
        connection = NWConnection(to: .hostPort(host: NWEndpoint.Host("localhost"),
                                                port: NWEndpoint.Port("50010")!),
                                  using: .udp)

        connection.stateUpdateHandler = { [weak self] status in
            if case .ready = status {
                self?.sendInitialFrame()
                self?.receive()
            }
        }

        // Restrict interfaces
        connection.parameters.prohibitedInterfaceTypes = [.cellular]

        // Restrict address families
        if let ipOptions = connection.parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            ipOptions.version = .v6
        }

        connection.start(queue: queue)
    }

    func stop() {
        print("#DEBUG: Client stopped")
        connection.cancelCurrentEndpoint()
    }

    private func sendInitialFrame() {
        let initialMsg = "Initial message"
        connection.send(content: initialMsg.data(using: .utf8), completion: NWConnection.SendCompletion.contentProcessed { error in
            if let error = error {
                print("#ERROR: Server send - \(error)")
                self.connection.restart()
            }
        })
    }

    private func receive() {
        connection.receiveMessage { [weak self] content, _, _, error in
            /* Handle received data */
            if let frame = content {
                self?.delegate?.receive(frame: frame)
            }

            guard error == nil else { return }
            self?.receive()
        }
    }
}
