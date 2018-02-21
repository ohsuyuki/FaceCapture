//
//  ImageProcessor.swift
//  testAmazonRekognitionSearchFace
//
//  Created by osu on 2018/02/15.
//  Copyright © 2018 osu. All rights reserved.
//

import Foundation
import UIKit

enum ErrorSearchFace {
    case unknown
}

struct Face {
    let feature: CIFaceFeature
    let rect: CGRect
    let mouth: CGPoint
    let rightEye: CGPoint
    let leftEye: CGPoint
}

class ImageProcessor {

    static let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorTracking: true])
    
    static func detectFaces(_ image: UIImage, ratioWidth: CGFloat, ratioHeight: CGFloat) -> [Face] {
        var detected: [Face] = []
        
        guard let detector = self.detector, let imageAsCIImage = CIImage(image: image) else {
            return detected
        }
        
        let faces = detector.features(in: imageAsCIImage) as NSArray
        for face in faces {
            guard let face = face as? CIFaceFeature else {
                continue
            }

            // rect
            let rect = face.bounds
            let x = rect.origin.x * ratioWidth
            let y = (image.size.height - rect.origin.y - rect.size.height) * ratioHeight
            let width = rect.width * ratioWidth
            let height = rect.height * ratioHeight

            let mouth = CGPoint(x: face.mouthPosition.x, y: (image.size.height - face.mouthPosition.y)).move(rx: ratioWidth, ry: ratioHeight)
            let rightEye = CGPoint(x: face.rightEyePosition.x, y: (image.size.height - face.rightEyePosition.y)).move(rx: ratioWidth, ry: ratioHeight)
            let leftEye = CGPoint(x: face.leftEyePosition.x, y: (image.size.height - face.leftEyePosition.y)).move(rx: ratioWidth, ry: ratioHeight)
            
            let faceStruct = Face(feature: face, rect: CGRect(x: x, y: y, width: width, height: height), mouth: mouth, rightEye: rightEye, leftEye: leftEye)
            detected.append(faceStruct)
        }
        
        return detected
    }
    
}

extension CGPoint {

    func move(rx: CGFloat, ry: CGFloat) -> CGPoint {
        return CGPoint(x: self.x * rx, y: self.y * ry)
    }

}
