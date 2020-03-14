//
//  PoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo

struct PoseEstimationKeypoint {
    let position: CGPoint
    let score: CGFloat
}

struct PoseEstimationHeatmaps {
    // <#TODO#>
    
    init(tfliteResult: TFLiteResult) {
        // <#TODO#>
    }
    
    var keypointsAndScore: [(position: CGPoint, score: CGFloat)] {
        // <#TODO#>
        return []
    }
}

enum PoseEstimationResult {
    case success(keypoints: [PoseEstimationKeypoint], heatmaps: PoseEstimationHeatmaps)
    case fail
}

/// for TensorFlowLite model
extension PoseEstimationResult {
    init(tfliteResult: TFLiteResult) {
        let heatmaps = PoseEstimationHeatmaps(tfliteResult: tfliteResult)
        let keypoints = heatmaps.keypointsAndScore.map { PoseEstimationKeypoint(position: $0.position, score: $0.score) }
        // <#TODO#>
        self = .success(keypoints: keypoints, heatmaps: heatmaps)
    }
}

protocol PoseEstimator {
    func predict(with pixelBuffer: CVPixelBuffer) -> PoseEstimationResult
}
