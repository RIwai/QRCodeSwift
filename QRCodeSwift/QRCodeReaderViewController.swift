//
//  QRCodeReaderViewController.swift
//  QRCodeSwift
//
//  Created by Ryota Iwai on 2016/05/09.
//  Copyright © 2016年 Ryota Iwai. All rights reserved.
//

import UIKit

import AVFoundation

// MARK: - Protocol
protocol QRCodeReaderViewControllerDelegate : class {
    func readStrings(readerViewController: QRCodeReaderViewController, strings: [String])
}

class QRCodeReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    // MARK: - Internal properties
    weak var delegate: QRCodeReaderViewControllerDelegate?

    // MARK: - Private properties
    private let captureSession = AVCaptureSession()
    private var inputCameras: [AVCaptureDevice] = []
    
    // MARK: - IBOutlet
    @IBOutlet weak var captureBaseView: UIView!
    @IBOutlet weak var cancelButton: UIButton!

    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup
        self.setupQRCodeReader()
    }

    // MARK: - Private
    private func setupQRCodeReader() {
        if !self.setupInputDevice() {
            return
        }
        if !self.setupOutputDevice() {
            return
        }

        self.setupCaptureLayer()

        self.captureSession.startRunning()
    }

    private func setupInputDevice() -> Bool {
        guard
            let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo),
            let captureDevices = devices as? [AVCaptureDevice] else {
                return false
        }

        for device in captureDevices {
            if device.position == .Back {
                self.inputCameras.insert(device, atIndex: 0)
            } else if device.position == .Front {
                self.inputCameras.append(device)
            }
            
            if self.inputCameras.count == 2 {
                break
            }
        }
        
        if self.inputCameras.count == 0 {
            return false
        }
        
        guard let camera = self.inputCameras.first else {
            return false
        }
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if !self.captureSession.canAddInput(input) {
                return false
            }
            self.captureSession.addInput(input)
            
            return true
        } catch {
            // Error
        }
        return false
    }

    private func setupOutputDevice() -> Bool {
        let output = AVCaptureMetadataOutput()
        if !self.captureSession.canAddOutput(output) {
            return false
        }
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        self.captureSession.addOutput(output)
        guard
            let outputTypes = output.availableMetadataObjectTypes as? [String]
            where outputTypes.contains(AVMetadataObjectTypeQRCode) else {
                return false
        }
        output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        return true
    }

    private func setupCaptureLayer() {
        let capturePreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        capturePreviewLayer.frame = UIScreen.mainScreen().bounds
        capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.captureBaseView.layer.addSublayer(capturePreviewLayer)
        
        return
    }

    private func changeCamera() {
        if self.inputCameras.count < 2 {
            return
        }
        
        guard let currentDeviceInput = self.captureSession.inputs.first as? AVCaptureDeviceInput else {
            return
        }
        self.captureSession.beginConfiguration()
        var camera: AVCaptureDevice?
        if currentDeviceInput.device.position == .Back {
            camera = self.inputCameras.last
        } else {
            camera = self.inputCameras.first
        }
        self.captureSession.removeInput(currentDeviceInput)
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }
        } catch {
            // Error
        }
        self.captureSession.commitConfiguration()
    }
    
    // MARK: - IBAction
    @IBAction func tapCameraChange(sender: AnyObject) {
        self.changeCamera()
        
        UIView.beginAnimations("Flip Camera View", context: nil)
        UIView.setAnimationDuration(0.4)
        UIView.setAnimationTransition(.FlipFromRight, forView: self.captureBaseView, cache: true)
        UIView.commitAnimations()
    }
    
    @IBAction func tapCancelButton(sender: AnyObject) {
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Slide)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func captureOutput(captureOutput: AVCaptureOutput!,
                       didOutputMetadataObjects metadataObjects: [AnyObject]!,
                                                fromConnection connection: AVCaptureConnection!) {
        var readStrings: [String] = []
        for object in metadataObjects {
            guard
                let metaDataObject = object as? AVMetadataMachineReadableCodeObject
                where metaDataObject.type == AVMetadataObjectTypeQRCode else {
                    continue
            }
            readStrings.append(metaDataObject.stringValue)
        }
        
        if readStrings.count > 0 {
            self.delegate?.readStrings(self, strings: readStrings)
        }
    }
}
