//
//  CFStreamClient.swift
//  NetworkingDemo
//
//  Created by Kamil Szczepański on 12/09/2018.
//  Copyright © 2018 Netguru. All rights reserved.
//

import Foundation
import CoreFoundation

final class CFStreamClient {

    var inputStream: InputStream!
    private var outputStream: OutputStream!

    private var readStream: Unmanaged<CFReadStream>?
    private var writeStream: Unmanaged<CFWriteStream>?

    func start() {
        close()
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           "localhost" as CFString,
                                           50010,
                                           &readStream,
                                           &writeStream)
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        inputStream.schedule(in: .current, forMode: .common)
        outputStream.schedule(in: .current, forMode: .common)
        inputStream.open()
        outputStream.open()

        let msg = "Initial msg"
        guard let data = msg.data(using: .utf8) else { return }
        _ = data.withUnsafeBytes { outputStream.write($0, maxLength: data.count) }
    }

    func close() {
        guard inputStream != nil, outputStream != nil else { return }
        inputStream.close()
        outputStream.close()
    }

    func send(data: Data) {
        _ = data.withUnsafeBytes { outputStream.write($0, maxLength: data.count) }
    }
}
