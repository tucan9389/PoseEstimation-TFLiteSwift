//
//  PoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo

struct Keypoint {
    let position: CGPoint
    let score: CGFloat
}

struct Keypoints {
    // <#TODO#>
    var keypoints: [Keypoint] = []
}

enum PoseEstimationError: Error {
    case failToCreateInputData
    case failToInference
}

protocol PoseEstimator {
    func inference(with pixelBuffer: CVPixelBuffer) -> Result<Keypoints, PoseEstimationError>
}
