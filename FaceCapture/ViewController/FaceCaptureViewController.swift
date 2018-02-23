//
//  FaceCaptureViewController.swift
//  FaceCapture
//
//  Created by osu on 2018/02/21.
//  Copyright © 2018 osu. All rights reserved.
//

import UIKit
import AVFoundation

enum CaptureFaceDirection: Int {

    case front = 0
    case up
    case rightUp
    case right
    case rightDown
    case down
    case leftDown
    case left
    case leftUp

    case count  // last

    func isEligible(rectArea: CGFloat) -> Bool {
        return (0.0...40.0).contains(rectArea)
    }

    func isEligible(distance: CGFloat) -> Bool {
        return (10000.0...CGFloat.greatestFiniteMagnitude).contains(distance)
    }

    func isEligible(angle: CGFloat) -> Bool {
        switch self {
        case .front:
            return true
        case .up:
            return 67.5 <= angle && angle < 112.5
        case .leftUp:
            return 112.5 <= angle && angle < 157.5
        case .left:
            return 157.5 <= angle && angle < 202.5
        case .leftDown:
            return 202.5 <= angle && angle < 247.5
        case .down:
            return 247.5 <= angle && angle < 292.5
        case .rightDown:
            return 292.5 <= angle && angle < 337.5
        case .right:
            return (337.5 <= angle && angle < 360) || (0 <= angle && angle < 22.5)
        case .rightUp:
            return 22.5 <= angle && angle < 67.5
        default:
            return false
        }
    }

    func isEligible(_ face: CaptureFaceSet) -> Bool {
        guard self == .front else {
            return false
        }

        // 顔の矩形の大きさ
        guard isEligible(rectArea: face.rectArea) == true else {
            return false
        }
        
        // 顔の中心と画像の中心の距離
        let distance = Geometria.calcDistance(face.center, org: face.centerImage)
        guard isEligible(distance: distance) == true else {
            return false
        }

        return true
    }

    func isEligible(_ face: CaptureFaceSet, front: CaptureFaceSet) -> Bool {
        guard self != .front else {
            return false
        }

        // 顔の矩形の大きさ
        guard isEligible(rectArea: face.rectArea) == true else {
            return false
        }

        // 顔の中心と正面の顔の中心の距離
        let distance = Geometria.calcDistance(face.center, org: front.center)
        guard isEligible(distance: distance) == true else {
            return false
        }

        // 正面の顔を原点としてときの顔の中心点の角度
        let angle = Geometria.calcAngle(face.center, org: front.center)
        guard isEligible(angle: angle) == true else {
            return false
        }

        return true
    }

}

class CaptureFaceSet {

    let feature: CIFaceFeature
    let image: UIImage

    var center: CGPoint { return Geometria.calcCircle(a: feature.rightEyePosition, b: feature.leftEyePosition, c: feature.mouthPosition).center }
    var triangleArea: CGFloat { return Geometria.calcAreaTriangle(a: feature.rightEyePosition, b: feature.leftEyePosition, c: feature.mouthPosition) }
    var centerImage: CGPoint { return CGPoint(x: image.size.width / 2, y: image.size.height / 2) }
    var rectArea: CGFloat { return feature.bounds.width * feature.bounds.height }

    init(feature: CIFaceFeature, image: UIImage) {
        self.feature = feature
        self.image = image
    }
}

class FaceCaptureController {

    var capturedFaceSets: [CaptureFaceSet?] = Array(repeating: nil, count: CaptureFaceDirection.count.rawValue)
    var regularPosition: CGPoint? = nil

    var targetDirections: [CaptureFaceDirection] = [.up, .rightUp, .right, .rightDown, .down, .leftDown, .left, .leftUp]

    // 検出された顔を検証して、登録可能な品質で撮影されていた保持
    func capture(_ faceSet: CaptureFaceSet) -> CaptureFaceDirection? {
        var captureFaceDirection: CaptureFaceDirection? = nil

        if let faceSetFront = capturedFaceSets[CaptureFaceDirection.front.rawValue] {
            // frontの顔画像が撮影済みなら、その他の角度の顔画像を取得
            for target in targetDirections {
                guard capturedFaceSets[target.rawValue] == nil else {
                    continue
                }
                
                if target.isEligible(faceSet, front: faceSetFront) == true {
                    captureFaceDirection = target
                    capturedFaceSets[target.rawValue] = faceSet
                    break
                }
            }
        } else {
            // frontの顔画像が未撮影なら、frontの顔画像を取得
            if CaptureFaceDirection.front.isEligible(faceSet) == true {
                captureFaceDirection = .front
                capturedFaceSets[CaptureFaceDirection.front.rawValue] = faceSet
            }
        }
        return captureFaceDirection
    }

}

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
    private let faceCaptureController: FaceCaptureController = FaceCaptureController()

    override var prefersStatusBarHidden: Bool { return true } // 撮影中は画面上部のステイタスを非表示

    override func viewDidLoad() {
        super.viewDidLoad()

        createSessionInstance()
    }

    override func viewDidAppear(_ animated: Bool) {
        self.sessionInstance?.session.startRunning()
        imageViewBounds = CGRect(origin: imageViewCapture.bounds.origin, size: imageViewCapture.bounds.size)
    }

    // 撮影された画像ごとに、顔の有無と品質を確認して、画面に映す
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = sampleBuffer.toImage() else {
            return
        }

        // 顔を検出
        let detectedFaces = ImageProcessor.detectFaces(image, ratioWidth: imageViewBounds.width / image.size.width, ratioHeight: imageViewBounds.height / image.size.height)

        // 2人以上の顔が検出されたら、どちらも登録対象としない。どちらが登録候補か判断しづらいので。
        var direction: CaptureFaceDirection? = nil
        if detectedFaces.count == 1, let face = detectedFaces.first {
            // 顔の確認
            direction = faceCaptureController.capture(CaptureFaceSet(feature: face.feature, image: image))
        }

        // 画面更新
        DispatchQueue.main.sync {
            imageViewCapture.image = image

            #if false
            cleanRects()
            for face in detectedFaces {
                drawOnImageView(face)
            }
            #endif

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

        #if false
            // mouth
            let pointMouth = imageViewCapture.convert(face.mouth, to: view)
            drawPoint(pointMouth, color: #colorLiteral(red: 1, green: 0, blue: 0.9713270068, alpha: 1))

            // eye
            let pointRightEye = imageViewCapture.convert(face.rightEye, to: view)
            drawPoint(pointRightEye, color: #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1))
            let pointLeftEye = imageViewCapture.convert(face.leftEye, to: view)
            drawPoint(pointLeftEye, color: #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1))
        #endif

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
