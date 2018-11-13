//
//  StreamViewController.swift
//  NetworkingDemo
//
//  Created by Kamil Szczepański on 17/09/2018.
//  Copyright © 2018 Netguru. All rights reserved.
//

import UIKit
import AVFoundation
import Network

final class CFStreamViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    private var cfStreamClient: CFStreamClient!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cfStreamClient = CFStreamClient()
        cfStreamClient.start()
        cfStreamClient.inputStream.delegate = self
    }
}

extension CFStreamViewController: StreamDelegate {

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            guard let inputStream = aStream as? InputStream else { return }
            readAvailableBytes(stream: inputStream)
        case Stream.Event.hasSpaceAvailable:
            print("#STREAM can accept bytes")
        case Stream.Event.endEncountered:
            print("#STREAM: endEncountered")
            cfStreamClient.start()
            navigationController?.popViewController(animated: true)
        case Stream.Event.errorOccurred:
            print("#STREAM: error occurred")
            cfStreamClient.start()
        case Stream.Event.hasSpaceAvailable:
            print("#STREAM: has space available")
        default:
            print("#STREAM: some other event")
        }
    }

    private func readAvailableBytes(stream: InputStream) {
        var numberOfBytesRead = 0
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 50000)
        while stream.hasBytesAvailable {
            numberOfBytesRead = stream.read(buffer, maxLength: 50000)
            if numberOfBytesRead < 0 {
                if stream.streamError != nil {
                    break
                }
            }
        }
        let data = Data(referencing: NSData(bytes: buffer, length: Int(UnsafeMutableRawPointer(buffer).load(as: UInt8.self))))
        guard let frame = UIImage(data: data) else { print("#ERROR: UIIMage from data"); return}
        DispatchQueue.main.async { [weak self] in
            self?.imageView.image = frame
        }
    }
}
