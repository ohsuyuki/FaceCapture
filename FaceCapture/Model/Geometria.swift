//
//  Geometria.swift
//  FaceCapture
//
//  Created by osu on 2018/02/22.
//  Copyright © 2018 osu. All rights reserved.
//

import Foundation
import UIKit

class Geometria {

    // 3点が直線で並ぶ時を考慮しない（メンゴ）
    public static func calcCircle(a: CGPoint, b: CGPoint, c: CGPoint) -> (center: CGPoint, r: CGFloat) {
        var circle: (center: CGPoint, r: CGFloat) = (CGPoint(x: 0, y: 0), 0.0)

        let kA = b.x - a.x
        let kB = b.y - a.y
        let kC = c.x - a.x
        let kD = c.y - a.y

        guard (kA != 0 && kD != 0) || (kB != 0 && kC != 0) else {
            return circle
        }

        let ox = a.x + (kD * (pow(kA, 2) + pow(kB, 2)) - kB * (pow(kC, 2) + pow(kD, 2))) / (kA * kD - kB * kC) / 2
        let oy = kB != 0 ?
            (kA * (a.x + b.x - ox - ox) + kB * (a.y + b.y)) / kB / 2 :
            (kC * (a.x + c.x - ox - ox) + kD * (a.y + c.y)) / kD / 2
        let center = CGPoint(x: ox, y: oy)
        
        let rA = calcDistance(center, org: a)
        let rB = calcDistance(center, org: b)
        let rC = calcDistance(center, org: c)

        circle.center = center
        circle.r = (rA + rB + rC) / 3.0
        
        return circle
    }

    public static func calcDistance(_ point: CGPoint, org: CGPoint) -> CGFloat {
        return sqrt(pow(point.x - org.x, 2) + pow(point.y - org.y, 2))
    }

    public static func calcAreaTriangle(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        return fabs((a.x - c.x)*(b.y - a.y) - (a.x - b.x)*(c.y - a.y)) / 2
    }

    public static func calcAngle(_ point: CGPoint, org: CGPoint) -> CGFloat {
        var r = atan2(point.y - org.y, point.x - org.x)
        if r < 0 {
            r = r + 2 * .pi
        }
        return floor(r * 360 / (2 * .pi))
    }
}
