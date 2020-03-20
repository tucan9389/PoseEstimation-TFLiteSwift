//
//  TFLiteFlatArray.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/18.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import TensorFlowLite

// MARK: - Wrappers
/// Struct for handling multidimension `Data` in flat `Array`.
struct TFLiteFlatArray<Element: AdditiveArithmetic> {
    private var array: [Element]
    var dimensions: [Int]
    
    init(tensor: Tensor) {
        dimensions = tensor.shape.dimensions
        array = tensor.data.toArray(type: Element.self)
    }
    
    private func flatIndex(_ index: [Int]) -> Int {
        guard index.count == dimensions.count else {
            fatalError("Invalid index: got \(index.count) index(es) for \(dimensions.count) index(es).")
        }
        
        var result = 0
        for i in 0..<dimensions.count {
            guard dimensions[i] > index[i] else {
                fatalError("Invalid index: \(index[i]) is bigger than \(dimensions[i])")
            }
            result = dimensions[i] * result + index[i]
        }
        return result
    }
    
    subscript(_ index: Int...) -> Element {
        get {
            return array[flatIndex(index)]
        }
        set(newValue) {
            array[flatIndex(index)] = newValue
        }
    }
}
