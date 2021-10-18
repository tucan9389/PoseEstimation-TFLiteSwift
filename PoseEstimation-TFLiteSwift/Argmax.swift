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
//  Argmax.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/05/23.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import Foundation
import TFLiteSwift_Vision

extension TFLiteFlatArray {
    func argmax(_ heatmapIndex: Int) -> (row: Int, col: Int, val: Float32) {
        var maxInfo = (row: 0, col: 0, val: self[heatmap: 0, 0, 0, heatmapIndex])
        let height = dimensions[1]
        let width = dimensions[2]
        for row in 0..<height {
            for col in 0..<width {
                if self[heatmap: 0, row, col, heatmapIndex] > maxInfo.val {
                    maxInfo = (row: row, col: col, val: self[0, row, col, heatmapIndex])
                }
            }
        }
        return maxInfo
    }
}
