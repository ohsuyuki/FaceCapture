//
//  FaceCaptureViewController.swift
//  FaceCapture
//
//  Created by osu on 2018/02/21.
//  Copyright © 2018 osu. All rights reserved.
//

import UIKit
import AVFoundation

class FaceCaptureViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var imageViewCapture: UIImageView!
    @IBOutlet weak var label: UILabel!

    @IBAction func showFeature(_ sender: Any) {
        if willCapture == true {
            willCapture = false
        } else {
            willCapture = true
            self.sessionInstance?.session.startRunning()
        }
    }

    private var sessionInstance: FactorySessionInstance? = nil
    private var imageViewBounds: CGRect!
    private var detectedFaceRect: [UIView] = []
    private var willCapture: Bool = true

    override var prefersStatusBarHidden: Bool { return true } // 撮影中は画面上部のステイタスを非表示

    override func viewDidLoad() {
        super.viewDidLoad()

        createSessionInstance()
    }

    override func viewDidAppear(_ animated: Bool) {
        self.sessionInstance?.session.startRunning()
        imageViewBounds = CGRect(origin: imageViewCapture.bounds.origin, size: imageViewCapture.bounds.size)
    }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = sampleBuffer.toImage() else {
            return
        }

        let detectedFaces = ImageProcessor.detectFaces(image, ratioWidth: imageViewBounds.width / image.size.width, ratioHeight: imageViewBounds.height / image.size.height)

        DispatchQueue.main.sync {
            imageViewCapture.image = image
            cleanRects()
            for face in detectedFaces {
                drawOnImageView(face.rect)
            }

            if willCapture == false {
                if let detected = detectedFaces.first?.feature {
                    showFeatureLabel(detected)
                }
                self.sessionInstance?.session.stopRunning()
            } else {
                label.text = ""
            }
        }
    }

    private func createSessionInstance() {
        let result = FactorySession.create()
        guard case Result<FactorySessionInstance, FactorySessionError>.success(let instance) = result else {
            return
        }
        
        sessionInstance = instance
        instance.output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "xgjwaifeyd"))
        
        // ouputの向きを縦向きに
        for connection in sessionInstance!.output.connections {
            guard connection.isVideoOrientationSupported == true else {
                continue
            }
            connection.videoOrientation = .portrait
        }
    }

    private func drawOnImageView(_ rect: CGRect) {
        let point = imageViewCapture.convert(rect.origin, to: view)
        let frame = CGRect(origin: point, size: CGSize(width: rect.width, height: rect.height))
        let viewRect = UIView(frame: frame)
        viewRect.layer.borderColor = #colorLiteral(red: 1, green: 0.9490688443, blue: 0, alpha: 1)
        viewRect.layer.borderWidth = 2
        view.addSubview(viewRect)
        detectedFaceRect.append(viewRect)
    }

    private func cleanRects() {
        for viewRect in detectedFaceRect {
            viewRect.removeFromSuperview()
        }
        detectedFaceRect.removeAll()
    }

    private func showFeatureLabel(_ faceFeature: CIFaceFeature) {
        let faceFeatureDic = faceFeature.dictionary()
        var featureStr = ""
        for (key, value) in faceFeatureDic {
            if featureStr.isEmpty == false {
                featureStr += "\n"
            }
            featureStr += "\(key) : \(value)"
        }
        label.text = featureStr
    }
}

extension CIFaceFeature {
    
    func dictionary() -> [String: Any] {
        let dic: [String: Any] = [
            "bounds": self.bounds,
            "hasLeftEyePosition": self.hasLeftEyePosition,
            "leftEyePosition": self.leftEyePosition,
            "hasRightEyePosition": self.hasRightEyePosition,
            "rightEyePosition": self.rightEyePosition,
            "hasMouthPosition": self.hasMouthPosition,
            "mouthPosition": self.mouthPosition,
            "hasTrackingID": self.hasTrackingID,
            "trackingID": self.trackingID,
            "hasTrackingFrameCount": self.hasTrackingFrameCount,
            "trackingFrameCount": self.hasTrackingFrameCount,
            "hasFaceAngle": self.hasFaceAngle,
            "faceAngle": self.faceAngle,
            "hasSmile": self.hasSmile,
            "leftEyeClosed": self.leftEyeClosed,
            "rightEyeClosed": self.rightEyeClosed
        ]
        return dic
    }
    
}
