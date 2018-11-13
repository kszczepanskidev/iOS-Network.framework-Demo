//
//  ViewController.swift
//  NetworkingDemoReceiver
//
//  Created by Kamil Szczepański on 25/09/2018.
//  Copyright © 2018 Netguru. All rights reserved.
//

import Cocoa
import AVFoundation
import Network

final class ViewController: NSViewController {

    private enum ServerType {
        case socket
        case asyncSocket
        case networkFramework
    }

    private let serverType: ServerType = .asyncSocket

    @IBOutlet weak var camera: NSView!

    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?

    private var frameworkServer: FrameworkUDPListener?
    private var socketServer: SocketUDPListener?
    private var asyncServer: AsyncSocketListener?

    override func viewDidLoad() {
        super.viewDidLoad()

        camera.layer = CALayer()
        captureSession.sessionPreset = AVCaptureSession.Preset.low
        let devices = AVCaptureDevice.devices()

        for device in devices {
            if ((device as AnyObject).hasMediaType(AVMediaType.video)) {
                print(device)
                captureDevice = device as AVCaptureDevice
            }
        }
        guard captureDevice != nil else { return }
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice!))
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = (self.camera.layer?.frame)!

            self.camera.layer?.addSublayer(previewLayer!)

            let videoOutput = AVCaptureVideoDataOutput()
            guard captureSession.canAddOutput(videoOutput) else { return }
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
            captureSession.sessionPreset = .low
            captureSession.addOutput(videoOutput)

            guard
                let connection = videoOutput.connection(with: .video),
                connection.isVideoMirroringSupported
            else {
                return
            }
            connection.isVideoMirrored = true

            captureSession.startRunning()

            switch serverType {
            case .asyncSocket:
                if asyncServer == nil {
                    asyncServer = AsyncSocketListener()
                    asyncServer?.start()
                }
            case .socket:
                if socketServer == nil {
                    socketServer = SocketUDPListener()
                    socketServer?.start()
                }
            case .networkFramework:
                if frameworkServer == nil {
                    frameworkServer = FrameworkUDPListener()
                }
            }
        } catch {
            print(AVCaptureSessionErrorKey.description)
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard
            let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            return
        }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let image = ciImage.convert()

        if let frame = image.compressedByFactor(0.75) {
            frameworkServer?.send(data: frame)
            socketServer?.send(frame)
            asyncServer?.send(frame)
        }
    }
}

extension CIImage {

    func convert() -> NSImage {
        let context = CIContext()
        let cgImage = context.createCGImage(self, from: self.extent)!
        return NSImage.init(cgImage: cgImage, size: NSZeroSize)
    }
}

extension NSImage {

    func compressedByFactor(_ factor: CGFloat) -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation else { return nil }
        let imageRep = NSBitmapImageRep(data: tiffRepresentation)
        let options = [NSBitmapImageRep.PropertyKey.compressionFactor: factor]
        let compressedData = imageRep?.representation(using: NSBitmapImageRep.FileType.jpeg, properties: options)
        return compressedData
    }
}
