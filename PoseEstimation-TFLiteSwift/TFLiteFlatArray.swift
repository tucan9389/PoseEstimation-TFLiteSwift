/*
* Copyright Doyoung Gwak 2020
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

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
class TFLiteFlatArray<Element: AdditiveArithmetic> {
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
    
    func element(at indexes: [Int]) -> Element {
        return array[flatIndex(indexes)]
    }
    
    subscript(indexes: Int...) -> Element {
        get { return array[flatIndex(indexes)] }
        set { array[flatIndex(indexes)] = newValue }
    }
}
