//
//  NumericExtension.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/05/03.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import Foundation

extension Optional where Wrapped == Float {
    var labelString: String {
        guard let value = self else { return "nil" }
        return String(format: "%.2f", value)
    }
}

extension Float32 {
    func string(_ format: String = "%.2f") -> String {
        return String(format: format, self)
    }
}

extension Optional where Wrapped == Float {
    static func *(lhs: Wrapped?, rhs: Float) -> Self {
        guard let lhs = lhs else { return nil }
        return some(lhs * rhs)
    }
}

extension Int {
    var labelString: String {
        return String(format: "%d", self)
    }
}

extension Optional where Wrapped == Int {
    var labelString: String {
        guard let value = self else { return "nil" }
        return value.labelString
    }
}
