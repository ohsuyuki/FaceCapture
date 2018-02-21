//
//  Result.swift
//  testAmazonRekognitionSearchFace
//
//  Created by osu on 2018/02/15.
//  Copyright © 2018 osu. All rights reserved.
//

import Foundation

enum Result<T, Error> {
    case success(T)
    case failure(Error)
}
