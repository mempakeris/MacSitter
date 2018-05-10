//
//  Utils.swift
//  MacSitter
//
//  Created by Matas Empakeris on 5/8/18.
//  Copyright © 2018 Matas Empakeris. All rights reserved.
//

import Foundation

extension Double {
    // Credits: https://www.uraimo.com/swiftbites/rounding-doubles-to-specific-decimal-places/
    public func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
