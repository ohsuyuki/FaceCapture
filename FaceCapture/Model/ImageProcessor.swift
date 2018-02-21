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
}

class ImageProcessor {
    
    static func detectFaces(_ image: UIImage, ratioWidth: CGFloat, ratioHeight: CGFloat) -> [Face] {
        var detected: [Face] = []
        
        guard let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]), let imageAsCIImage = CIImage(image: image) else {
            return detected
        }
        
        let faces = detector.features(in: imageAsCIImage) as NSArray
        for face in faces {
            guard let face = face as? CIFaceFeature else {
                continue
            }

            let rect = face.bounds
            let x = rect.origin.x * ratioWidth
            let y = (image.size.height - rect.origin.y - rect.size.height) * ratioHeight
            let width = rect.width * ratioWidth
            let height = rect.height * ratioHeight

            let faceStruct = Face(feature: face, rect: CGRect(x: x, y: y, width: width, height: height))
            detected.append(faceStruct)
        }
        
        return detected
    }
    
}

