//
//  PoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo

enum PoseEstimationResult {
    case success(keypoints: [Keypoint], heatmaps: Heatmaps)
    case fail
    
    struct Keypoint {
        let position: CGPoint
        let score: CGFloat
    }
    struct Heatmaps {
        // <#TODO#>
        
        init(tfliteResult: TFLiteResult) {
            // <#TODO#>
        }
        
        var keypointsAndScore: [(position: CGPoint, score: CGFloat)] {
            // <#TODO#>
            return []
        }
    }
}

/// for TensorFlowLite model
extension PoseEstimationResult {
    init(tfliteResult: TFLiteResult) {
        let heatmaps = Heatmaps(tfliteResult: tfliteResult)
        let keypoints = heatmaps.keypointsAndScore.map { Keypoint(position: $0.position, score: $0.score) }
        // <#TODO#>
        self = .success(keypoints: keypoints, heatmaps: heatmaps)
    }
}

protocol PoseEstimator {
    func inference(with pixelBuffer: CVPixelBuffer) -> PoseEstimationResult
}
