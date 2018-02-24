//
//  ExtensionCMSampleBufferGetImageBuffer.swift
//  testAmazonRekognitionSearchFace
//
//  Created by osu on 2018/02/15.
//  Copyright © 2018 osu. All rights reserved.
//

import Foundation
import CoreMedia
import UIKit

extension CMSampleBuffer {

    func toImage(mirrored: Bool) -> UIImage? {
        guard let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(self) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0) else {
            return nil
        }
        
        let bytesPerRow: UInt = UInt(CVPixelBufferGetBytesPerRow(imageBuffer))
        let width: UInt = UInt(CVPixelBufferGetWidth(imageBuffer))
        let height: UInt = UInt(CVPixelBufferGetHeight(imageBuffer))
        
        let bitsPerCompornent: UInt = 8
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue).union(CGBitmapInfo.byteOrder32Little)
        guard let newContext = CGContext(data: baseAddress, width: Int(width), height: Int(height), bitsPerComponent: Int(bitsPerCompornent), bytesPerRow: Int(bytesPerRow), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }

        guard let cgImage = newContext.makeImage() else {
            return nil
        }

        if mirrored == false {
            return UIImage(cgImage: cgImage)
        }

        guard let mirroredContext = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: Int(bitsPerCompornent), bytesPerRow: Int(bytesPerRow), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }

        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: CGFloat(width), y: 0.0)
        transform = transform.scaledBy(x: -1, y: 1)
        mirroredContext.concatenate(transform)
        mirroredContext.draw(cgImage, in: CGRect(x: 0, y:0, width: Int(width), height: Int(height)))

        guard let mirroredCgImage = mirroredContext.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: mirroredCgImage)
    }

}
