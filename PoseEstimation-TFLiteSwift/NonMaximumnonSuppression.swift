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
//  NonMaximumnonSuppression.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/04/15.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import Foundation
import TFLiteSwift_Vision

class NonMaximumnonSuppression {
    typealias MaximumPoint = (col: Int, row: Int, val: Float32)
    
    static func process(_ heatmap: TFLiteFlatArray, partIndex: Int, width: Int, height: Int) -> [MaximumPoint] {
        let filterSize = 3
        var lastMaximumColumns: [MaximumPoint?] = (0..<width).map { _ in nil }
        var results: [MaximumPoint] = []
        results.reserveCapacity(20)
        
        for row in (0..<height) {
            for col in (0..<width) {
                var smallerColumns: [Int] = []
                var hasBiggerValueInFilterSize = false
                for targetColumn in max(col-filterSize, 0)...min(col+filterSize, width-1) {
                    if let lastMaximumPoint = lastMaximumColumns[targetColumn] {
                        if lastMaximumPoint.val < heatmap[heatmap: 0, row, col, partIndex] {
                            // 작은건 저장
                            smallerColumns.append(targetColumn)
                        } else if lastMaximumPoint.val > heatmap[heatmap: 0, row, col, partIndex] {
                            // 더 큰 경우가 있으면 끝, 버리기
                            hasBiggerValueInFilterSize = true
                            break
                        }
                    }
                }
                if !hasBiggerValueInFilterSize {
                    for smallerColumn in smallerColumns {
                        lastMaximumColumns[smallerColumn] = nil
                    }
                    lastMaximumColumns[col] = (col: col, row: row, val: heatmap[heatmap: 0, row, col, partIndex])
                }
                // 정리
                if let lastMaximumPoint = lastMaximumColumns[col] {
                    if lastMaximumPoint.row < row-filterSize {
                        for targetColumn in col...min(col+filterSize*2, width-1) {
                            if let compareLastMaximumPoint = lastMaximumColumns[targetColumn],
                                lastMaximumPoint.row == compareLastMaximumPoint.row,
                                lastMaximumPoint.col == compareLastMaximumPoint.col {
                                lastMaximumColumns[targetColumn] = nil
                            }
                        }
                        results.append((col: lastMaximumPoint.col,
                                        row: lastMaximumPoint.row,
                                        val: lastMaximumPoint.val))
                    }
                }
            }
        }
        
        // 마지막 남은 것 정리
        for (offset, lastMaximumPoint) in lastMaximumColumns.enumerated() {
            guard let lastMaximumPoint = lastMaximumPoint else { continue }
            for targetColumn in offset...min(offset+filterSize*2, width-1) {
                if let compareLastMaximumPoint = lastMaximumColumns[targetColumn],
                    lastMaximumPoint.row == compareLastMaximumPoint.row,
                    lastMaximumPoint.col == compareLastMaximumPoint.col {
                    lastMaximumColumns[targetColumn] = nil
                }
            }
            results.append((col: lastMaximumPoint.col,
                            row: lastMaximumPoint.row,
                            val: lastMaximumPoint.val))
        }
        
        return results
    }
    
    
    
}
