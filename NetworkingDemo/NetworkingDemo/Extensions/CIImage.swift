//
//  CIImage.swift
//  NetworkingDemo
//
//  Created by Kamil Szczepański on 17/09/2018.
//  Copyright © 2018 Netguru. All rights reserved.
//

import UIKit

extension CIImage {

    func convert() -> UIImage {
        let context = CIContext()
        let cgImage = context.createCGImage(self, from: self.extent)!
        return UIImage.init(cgImage: cgImage)
    }
}
