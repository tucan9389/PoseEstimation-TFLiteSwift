//
//  NonMaximumnonSuppression.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/04/15.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import Foundation

class NonMaximumnonSuppression {
    typealias MaximumPoint = (row: Int, col: Int, val: Float32)
    
    static func process(_ heatmap: TFLiteFlatArray<Float32>, partIndex: Int, width: Int, height: Int) -> [MaximumPoint] {
        let filterSize = 3
        var lastMaximumColumns: [MaximumPoint?] = (0..<width).map { _ in nil }
        var results: [MaximumPoint] = []
        
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
                        results.append((row: lastMaximumPoint.row,
                                        col: lastMaximumPoint.col,
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
            results.append((row: lastMaximumPoint.row,
                            col: lastMaximumPoint.col,
                            val: lastMaximumPoint.val))
        }
        
        return results
    }
    
    
    
}
