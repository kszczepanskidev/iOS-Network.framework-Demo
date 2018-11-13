//
//  AsyncSocketClientViewController.swift
//  NetworkingDemo
//
//  Created by Kamil Szczepański on 23/10/2018.
//  Copyright © 2018 Netguru. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

final class AsyncSocketClientViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    private var asyncClient: AsyncSocketClient!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        asyncClient = AsyncSocketClient(delegate: self)
        asyncClient.start()
    }
}

extension AsyncSocketClientViewController: GCDAsyncUdpSocketDelegate {

    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        if let string = String(data: data, encoding: .utf8) { print("#DEBUG received: \(string)") }

        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        do {
            try address.withUnsafeBytes { (pointer: UnsafePointer<sockaddr>) -> Void in
                guard getnameinfo(pointer, socklen_t(address.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
                    throw NSError(domain: "domain", code: 0, userInfo: ["error": "unable to get ip address"])
                }
            }
        } catch {
            print(error)
            return
        }
        print("#DEBUG address: \(String(cString: hostname))")

        guard let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
}
