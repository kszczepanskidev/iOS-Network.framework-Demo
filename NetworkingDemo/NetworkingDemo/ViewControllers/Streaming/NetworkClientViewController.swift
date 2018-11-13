//
//  ClientViewController.swift
//  NetworkingDemo
//
//  Created by Kamil Szczepański on 17/09/2018.
//  Copyright © 2018 Netguru. All rights reserved.
//

import UIKit

final class UDPClientViewController: UIViewController {
     
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!

    private var udpClient: UDPClient!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        udpClient = UDPClient()
        udpClient.delegate = self
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        udpClient.stop()
    }
}

extension UDPClientViewController: VideoFrameReceiver {

    func receive(frame: Data) {
        DispatchQueue.main.async {
            guard let string = String(data: frame, encoding: .utf8) else { return }
            self.label.text = string
        }
        guard let image = UIImage(data: frame) else { return }
        DispatchQueue.main.async { [unowned self] in
            self.imageView.image = image
        }
    }
}
