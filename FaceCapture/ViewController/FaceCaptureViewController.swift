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
                drawOnImageView(face)
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

    private func drawOnImageView(_ face: Face) {
        let point = imageViewCapture.convert(face.rect.origin, to: view)
        let frame = CGRect(origin: point, size: CGSize(width: face.rect.width, height: face.rect.height))
        let viewRect = UIView(frame: frame)
        viewRect.layer.borderColor = #colorLiteral(red: 1, green: 0.9490688443, blue: 0, alpha: 1)
        viewRect.layer.borderWidth = 2
        view.addSubview(viewRect)

        let label = UILabel(frame: CGRect(x: 0, y: -24, width: viewRect.bounds.width, height: 24))
        label.textColor = #colorLiteral(red: 1, green: 0.9490688443, blue: 0, alpha: 1)
        label.numberOfLines = 1
        label.textAlignment = .center
        label.text = String("ID : \(face.feature.trackingID)")
        viewRect.addSubview(label)

        // mouth
        let pointMouth = imageViewCapture.convert(face.mouth, to: view)
        drawPoint(pointMouth, color: #colorLiteral(red: 1, green: 0, blue: 0.9713270068, alpha: 1))

        // eye
        let pointRightEye = imageViewCapture.convert(face.rightEye, to: view)
        drawPoint(pointRightEye, color: #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1))
        let pointLeftEye = imageViewCapture.convert(face.leftEye, to: view)
        drawPoint(pointLeftEye, color: #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1))

        detectedFaceRect.append(viewRect)
    }

    private func cleanRects() {
        for viewRect in detectedFaceRect {
            viewRect.removeFromSuperview()
        }
        detectedFaceRect.removeAll()
    }

    private func showFeatureLabel(_ faceFeature: CIFaceFeature) {
        let faceFeatureArr = faceFeature.stringArray()
        let featureStr = faceFeatureArr.reduce("") { con, v in
            con + v + "\n"
        }
        label.text = featureStr
    }

    private func drawPoint(_ point: CGPoint, color: CGColor) {
        let frame = CGRect(origin: point, size: CGSize(width: 4, height: 4))
        let uiView = UIView(frame: frame)
        uiView.layer.borderColor = color
        uiView.layer.borderWidth = 4
        view.addSubview(uiView)
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
            "trackingFrameCount": self.trackingFrameCount,
            "hasFaceAngle": self.hasFaceAngle,
            "faceAngle": self.faceAngle,
            "hasSmile": self.hasSmile,
            "leftEyeClosed": self.leftEyeClosed,
            "rightEyeClosed": self.rightEyeClosed
        ]
        return dic
    }

    func stringArray() -> [String] {
        return [
            "bounds : \(bounds)",
            "hasLeftEyePosition : \(hasLeftEyePosition)",
            "leftEyePosition : \(leftEyePosition)",
            "hasRightEyePosition : \(hasRightEyePosition)",
            "rightEyePosition : \(rightEyePosition)",
            "hasMouthPosition : \(hasMouthPosition)",
            "mouthPosition : \(mouthPosition)",
            "hasTrackingID : \(hasTrackingID)",
            "trackingID : \(trackingID)",
            "hasTrackingFrameCount : \(hasTrackingFrameCount)",
            "trackingFrameCount : \(trackingFrameCount)",
            "hasFaceAngle : \(hasFaceAngle)",
            "faceAngle : \(faceAngle)",
            "hasSmile : \(hasSmile)",
            "leftEyeClosed : \(leftEyeClosed)",
            "rightEyeClosed : \(rightEyeClosed)"
        ]
    }

}
