//
//  FuctorySession.swift
//  testAmazonRekognitionSearchFace
//
//  Created by osu on 2018/02/15.
//  Copyright © 2018 osu. All rights reserved.
//

import Foundation
import AVFoundation

struct FactorySessionInstance {
    let session: AVCaptureSession
    let device: AVCaptureDevice
    let input: AVCaptureDeviceInput
    let output: AVCaptureVideoDataOutput
}

enum FactorySessionError {
    case couldNotDiscoverSession
    case couldNotCreateInput
    case couldNotAddInput
    case couldNotAddOutput
}

class FactorySession {

    static func create() -> Result<FactorySessionInstance, FactorySessionError> {
        // 全面のカメラを取得
        guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first else {
            return .failure(.couldNotDiscoverSession)
        }
        
        // セッション作成
        let session = AVCaptureSession()
        // 解像度の設定
        session.sessionPreset = .high
        
        // カメラをinputに
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            return .failure(.couldNotCreateInput)
        }
        guard session.canAddInput(input) == true else {
            return .failure(.couldNotAddInput)
        }
        session.addInput(input)
        
        // outputの構成と設定
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA ]
        output.alwaysDiscardsLateVideoFrames = true
        guard session.canAddOutput(output) == true else {
            return .failure(.couldNotAddOutput)
        }
        session.addOutput(output)

        return .success(FactorySessionInstance(session: session, device: device, input: input, output: output))
    }

}
