//
//  ViewController.swift
//  QRCodeSwift
//
//  Created by Ryota Iwai on 2016/05/09.
//  Copyright © 2016年 Ryota Iwai. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, QRCodeReaderViewControllerDelegate {

    // MARK: - IBOutlet
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var createQRCodeButton: UIButton!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var readQRCodeTextView: UITextView!
    @IBOutlet weak var readQRCodeButton: UIButton!

    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()

        // For QR Code Image to sharp
        self.qrCodeImageView.layer.magnificationFilter = kCAFilterNearest
        self.qrCodeImageView.contentMode = .scaleAspectFit
    }

    // MARK: - Private
    private func createQRCode() {
        guard let currentText = self.textField.text else {
            // Error
            self.qrCodeImageView.isHidden = true
            return
        }
        
        // Create filter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            // Error
            self.qrCodeImageView.isHidden = true
            return
        }
        filter.setDefaults()

        // Set input text
        guard let inputData = currentText.data(using: .utf8) else {
            // Error
            self.qrCodeImageView.isHidden = true
            return
        }
        filter.setValue(inputData, forKey: "inputMessage")
        
        // Set Level
        filter.setValue("L", forKey: "inputCorrectionLevel")
        
        // Create CIImage
        guard let ciImage = filter.outputImage else {
            // Error
            self.qrCodeImageView.isHidden = true
            return
        }
        // Convert to CGImage
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            // Error
            self.qrCodeImageView.isHidden = true
            return
        }
        // Convert to UIImage and set to UIImageView
        let uiimage = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
        self.qrCodeImageView.image = uiimage
        self.qrCodeImageView.isHidden = false
    }

    // MARK: - IBAction
    @IBAction func tapCreateQRCodeButton(sender: AnyObject) {
        self.textField.resignFirstResponder()
        self.createQRCode()
    }

    @IBAction func tapReadQRCodeButton(sender: AnyObject) {
        #if arch(i386) || arch(x86_64)
            // simulator
            return
        #endif
        
        guard let readerViewController = UIStoryboard.init(name: "QRCodeReaderViewController", bundle: nil).instantiateInitialViewController() as? QRCodeReaderViewController else {
            return
        }
        readerViewController.delegate = self
        UIApplication.shared.setStatusBarHidden(true, with: .slide)
        self.present(readerViewController, animated: true, completion: nil)
        self.readQRCodeTextView.text = ""
    }

    // MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let currentText = self.textField.text else {
            self.createQRCodeButton.isEnabled = true
            return true
        }
        let length = currentText.characters.count - range.length + string.characters.count
        if length > 0 {
            self.createQRCodeButton.isEnabled = true
        } else {
            self.createQRCodeButton.isEnabled = false
        }
        
        return true
    }
    
    private func textFieldShouldClear(textField: UITextField) -> Bool {
        self.createQRCodeButton.isEnabled = false
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textField.resignFirstResponder()
        return true
    }

    // MARK: - QRCodeReaderViewControllerDelegate
    func readStrings(readerViewController: QRCodeReaderViewController, strings: [String]) {
        UIApplication.shared.setStatusBarHidden(false, with: .slide)
        readerViewController.dismiss(animated: true) {
            for string in strings {
                self.readQRCodeTextView.text = self.readQRCodeTextView.text?.appendingFormat(string + "\n\n") ?? string + "\n\n"
            }
            self.readQRCodeTextView.isHidden = false
        }
    }
}

