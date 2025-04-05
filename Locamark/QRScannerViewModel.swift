//
//  QRScannerViewModel.swift
//  Locamark
//
//  Created by Chu Ba Manh on 08/03/2025.
//

import AVFoundation
import UIKit

class QRScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isScanning = false
    @Published var scannedData: String?
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    func startScanning(in view: UIView, completion: @escaping (String?) -> Void) {
        guard !isScanning else { return }

        let session = AVCaptureSession()
        self.session = session

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("No video device found")
            completion(nil)
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            let metadataOutput = AVCaptureMetadataOutput()

            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                print("Could not add video input")
                completion(nil)
                return
            }

            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                print("Could not add metadata output")
                completion(nil)
                return
            }

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer

            session.startRunning()
            isScanning = true
        } catch {
            print("Error setting up capture session: \(error.localizedDescription)")
            completion(nil)
        }
    }

    func stopScanning() {
        session?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        isScanning = false
        scannedData = nil
    }

    // Quét mã QR từ ảnh
    func scanQRFromImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let ciImage = CIImage(image: image) else {
            print("Failed to convert image to CIImage")
            completion(nil)
            return
        }

        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) ?? []

        if let qrCodeFeature = features.first as? CIQRCodeFeature {
            completion(qrCodeFeature.messageString)
        } else {
            print("No QR code found in image")
            completion(nil)
        }
    }

    // Delegate để xử lý khi quét được mã QR từ camera
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue {
            stopScanning()
            scannedData = stringValue
        }
    }
}
