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

class ImageProcessor {

    static func detectFaces(_ image: UIImage, ratioWidth: CGFloat, ratioHeight: CGFloat) -> [CGRect] {
        var rects: [CGRect] = []
        
        guard let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]), let imageAsCIImage = CIImage(image: image) else {
            return rects
        }
        
        let faces = detector.features(in: imageAsCIImage) as NSArray
        for face in faces {
            guard let rect = (face as AnyObject).bounds else {
                continue
            }

            let x = rect.origin.x * ratioWidth
            let y = (image.size.height - rect.origin.y - rect.size.height) * ratioHeight
            let width = rect.width * ratioWidth
            let height = rect.height * ratioHeight

            rects.append(CGRect(x: x, y: y, width: width, height: height))
        }

        return rects
    }

}
