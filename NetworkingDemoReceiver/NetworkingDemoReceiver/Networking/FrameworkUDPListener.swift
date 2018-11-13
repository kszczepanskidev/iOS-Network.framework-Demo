//
//  UDPListener.swift
//  NetworkingDemoReceiver
//
//  Created by Kamil Szczepański on 17/10/2018.
//  Copyright © 2018 Netguru. All rights reserved.
//

import Foundation
import Network

final class FrameworkUDPListener {

    var isConnected = false

    private let listener: NWListener
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "UDP Sender Queue")

    private var sendErrorHandler: NWConnection.SendCompletion!

    init?() {
        do {
            listener = try NWListener(using: .udp, on: NWEndpoint.Port("50010")!)
        } catch {
            return nil
        }
        connection?.parameters.allowFastOpen = true
        let initialData = Data()
        connection?.send(content: initialData, completion: .idempotent)

        listener.newConnectionHandler = { [unowned self] connection in
            print("#DEBUG: Server - new connection")
            self.connection = connection
            connection.start(queue: self.queue)
            self.isConnected = true
        }

        listener.stateUpdateHandler = { [unowned self] state in
            switch state {
            case .ready:
                guard let port = self.listener.port else { break }
                print("#DEBUG: Server - Listening on \(port)")
            case .failed(let error):
                print("#ERROR: Server - \(error.localizedDescription)")
            case .cancelled:
                print("#ERROR: Server - cancelled")
                self.connection?.restart()
                self.isConnected = false
            default:
                print("#DEBUG: Server - \(state)")
            }
        }

        sendErrorHandler = NWConnection.SendCompletion.contentProcessed { error in
            if let error = error {
                print("#ERROR: Server send - \(error)")
                self.connection?.restart()
            }
        }
        
        listener.start(queue: queue)
    }

    func send(data: Data) {
        guard isConnected else { return }
        connection?.send(content: data, completion: sendErrorHandler)
    }

func readHeader(connection: NWConnection) {
    let headerLength = 10
    connection.receive(minimumIncompleteLength: headerLength, maximumLength: headerLength) { content, _, _, error in
        if let error = error {
            /* Handle error */
        }
        /* Parse received header */
        /* Read rest of the body */
    }
}
}
