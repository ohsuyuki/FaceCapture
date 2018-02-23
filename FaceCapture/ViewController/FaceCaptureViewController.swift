//
//  FaceCaptureViewController.swift
//  FaceCapture
//
//  Created by osu on 2018/02/21.
//  Copyright © 2018 osu. All rights reserved.
//

import UIKit
import AVFoundation

enum FaceCaptureDirection: Int {

    case right = 0
    case rightUp
    case up
    case leftUp
    case left
    case leftDown
    case down
    case rightDown
    case front // count

    static var eligibleRectArea: ClosedRange<CGFloat> = (100.0...CGFloat.greatestFiniteMagnitude)
    private func isEligible(rectArea: CGFloat) -> Bool {
        return FaceCaptureDirection.eligibleRectArea.contains(rectArea)
    }

    static var eligibleDistance: ClosedRange<CGFloat> = (0.0...200.0)
    private func isEligible(distance: CGFloat) -> Bool {
        return FaceCaptureDirection.eligibleDistance.contains(distance)
    }

    static let angleDiff: CGFloat = (2.0 * CGFloat.pi) / CGFloat(FaceCaptureDirection.front.rawValue)
    var eligibleAngle: CGFloat { return FaceCaptureDirection.angleDiff * CGFloat(self.rawValue) }
    func isEligible(angle: CGFloat) -> Bool {
        let angleDiffHalf = FaceCaptureDirection.angleDiff / CGFloat(2.0)
        switch self {
        case .front:
            return true
        case .right:
            return (((2.0 * CGFloat.pi) - eligibleAngle) <= angle && angle < 0) || (0 <= angle && angle < (eligibleAngle + angleDiffHalf))
        default:
            return (eligibleAngle - angleDiffHalf) <= angle && angle < (eligibleAngle + angleDiffHalf)
        }
    }

    func isEligible(_ face: FaceCaptureSet) -> Bool {
        print("face area : \(face.feature.bounds.area)")
        // 顔の矩形の大きさ
        guard isEligible(rectArea: face.feature.bounds.area) == true else {
            return false
        }
        
        // 顔の中心と画像の中心の距離
        let distance = Geometria.calcDistance(face.feature.center, org: face.image.center)
        print("distance : \(distance), feature.center : \(face.feature.center), image.center : \(face.image.center)")
        guard isEligible(distance: distance) == true else {
            return false
        }

        // 画像の中心から顔の中心点の角度
        let angle = Geometria.calcAngle(face.feature.center, org: face.image.center)
        print(angle)
        guard isEligible(angle: angle) == true else {
            return false
        }

        return true
    }

    #if false
    func isEligible(_ face: FaceCaptureSet, front: FaceCaptureSet) -> Bool {
        guard self != .front else {
            return false
        }

        print(face.feature.bounds.area)
        // 顔の矩形の大きさ
        guard isEligible(rectArea: face.feature.bounds.area) == true else {
            return false
        }

        // 顔の中心と正面の顔の中心の距離
        let distance = Geometria.calcDistance(face.feature.center, org: front.feature.center)
        print(distance)
        guard isEligible(distance: distance) == true else {
            return false
        }

        // 正面の顔を原点としてときの顔の中心点の角度
        let angle = Geometria.calcAngle(face.feature.center, org: front.feature.center)
        print(angle)
        guard isEligible(angle: angle) == true else {
            return false
        }

        return true
    }
    #endif
}

class FaceCaptureSet {

    let feature: CIFaceFeature
    let image: UIImage

    init(feature: CIFaceFeature, image: UIImage) {
        self.feature = feature
        self.image = image
    }

}

class FaceCaptureController {

    var capturedFaceSets: [FaceCaptureSet?] = Array(repeating: nil, count: FaceCaptureDirection.front.rawValue + 1)
    var isCapturedFaceSetsFull: Bool {
        for captured in capturedFaceSets {
            guard captured != nil else {
                return false
            }
        }
        return true
    }

    // 検出された顔を検証して、登録可能な品質で撮影されていた保持
    func capture(_ faceSet: FaceCaptureSet) -> FaceCaptureDirection? {
        var faceCaptureDirection: FaceCaptureDirection? = nil

        if let _ = capturedFaceSets[FaceCaptureDirection.front.rawValue] {
            // frontの顔画像が撮影済みなら、その他の角度の顔画像を取得
            for target in 0..<FaceCaptureDirection.front.rawValue {
                guard capturedFaceSets[target] == nil else {
                    continue
                }
                
                if FaceCaptureDirection(rawValue :target)!.isEligible(faceSet) == true {
                    faceCaptureDirection = FaceCaptureDirection(rawValue: target)
                    capturedFaceSets[target] = faceSet
                }
            }
        } else {
            // frontの顔画像が未撮影なら、frontの顔画像を取得
            if FaceCaptureDirection.front.isEligible(faceSet) == true {
                faceCaptureDirection = .front
                capturedFaceSets[FaceCaptureDirection.front.rawValue] = faceSet
            }
        }
        return faceCaptureDirection
    }

}

class FaceCaptureViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var imageViewCapture: UIImageView!

    private var sessionInstance: FactorySessionInstance? = nil
    private var imageViewBounds: CGRect!
    private let faceCaptureController: FaceCaptureController = FaceCaptureController()
    private var guideLayers: [CAShapeLayer] = []
    private let storeImage = Store<UIImage>(label: "imageStore")
    private let willCapture = Store<Bool>(label: "willCapture")
    private let queueImageProcess = DispatchQueue(label: "imageProcess")

    override var prefersStatusBarHidden: Bool { return true } // 撮影中は画面上部のステイタスを非表示

    override func viewDidLoad() {
        super.viewDidLoad()

        createSessionInstance()
    }

    override func viewDidAppear(_ animated: Bool) {
        self.sessionInstance?.session.startRunning()
        imageViewBounds = CGRect(origin: imageViewCapture.bounds.origin, size: imageViewCapture.bounds.size)

        drawGuide()
    }

    // 撮影された画像ごとに、顔の有無と品質を確認して、画面に映す
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if willCapture.get() == false {
            // 終了処理
            self.sessionInstance?.session.stopRunning()
//            DispatchQueue.main.async {
//
//            }
            return
        }

        guard let image = sampleBuffer.toImage(mirrored: true) else {
            return
        }

        // 画面更新
        DispatchQueue.main.async {
            self.imageViewCapture.image = image
        }

        // 顔検出中の画像の有無を確認
        guard storeImage.get() == nil else {
            return
        }
        storeImage.set(image)

        // 顔検出
        queueImageProcess.async {
            self.detectFace()
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

    private func drawGuide() {
        let radius = imageViewCapture.bounds.width * 0.6
        let center = imageViewCapture.bounds.center

        for i in 0...FaceCaptureDirection.front.rawValue {
            let path = UIBezierPath()
            let guideLayer = CAShapeLayer()

            if i == FaceCaptureDirection.front.rawValue {
                // 正面に対応するガイドは外周園
                path.move(to: center.move(dx: radius, dy: 0))
                path.addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
                path.close()
                path.stroke()
                guideLayer.fillColor = UIColor.clear.cgColor
            } else {
                // 顔の角度毎のガイド
                let destinationRelational = Geometria.calcPoint(angle: FaceCaptureDirection(rawValue: i)!.eligibleAngle, distance: radius * 0.8)
                let destination = destinationRelational.move(dx: center.x, dy: center.y)
                path.move(to: center)
                path.addLine(to: destination)
                path.stroke()
            }

            guideLayer.lineWidth = 3
            guideLayer.lineDashPattern = [ 10.0, 8.0 ]
            guideLayer.strokeColor = UIColor.white.cgColor
            guideLayer.path = path.cgPath

            guideLayers.append(guideLayer)
            imageViewCapture.layer.addSublayer(guideLayer)
        }
    }

    private func detectFace() {
        guard let image = storeImage.get() else {
            return
        }

        // 顔を検出
        let detectedFaces = ImageProcessor.detectFaces(image, ratioWidth: imageViewBounds.width / image.size.width, ratioHeight: imageViewBounds.height / image.size.height)
        
        // 2人以上の顔が検出されたら、どちらも登録対象としない。どちらが登録候補か判断しづらいので。
        var direction: FaceCaptureDirection? = nil
        if detectedFaces.count == 1, let face = detectedFaces.first {
            // 顔の確認
            direction = faceCaptureController.capture(FaceCaptureSet(feature: face.feature, image: image))
        }

        print("direction : \(direction)")

        guard let directionCaptured = direction else {
            self.storeImage.set(nil)
            return
        }

        DispatchQueue.main.async {
            self.guideLayers[directionCaptured.rawValue].strokeColor = #colorLiteral(red: 1, green: 0.9490688443, blue: 0, alpha: 1)
            if self.faceCaptureController.isCapturedFaceSetsFull == true {
                self.willCapture.set(false)
            }
            self.storeImage.set(nil)
        }
    }

}

extension CIFaceFeature {

    var center: CGPoint { return Geometria.calcCircle(a: self.rightEyePosition, b: self.leftEyePosition, c: self.mouthPosition).center }
    var triangleArea: CGFloat { return Geometria.calcAreaTriangle(a: self.rightEyePosition, b: self.leftEyePosition, c: self.mouthPosition) }

}

extension CGRect {

    var area: CGFloat { return self.width * self.height }
    var center: CGPoint { return CGPoint(x: self.origin.x + self.width / 2, y: self.origin.y + self.height / 2) }

}

extension UIImage {

    var center: CGPoint { return CGPoint(x: self.size.width / 2, y: self.size.height / 2) }

}
