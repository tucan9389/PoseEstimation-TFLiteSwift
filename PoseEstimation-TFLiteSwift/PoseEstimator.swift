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

struct PoseEstimationOutput {
    typealias Line = (from: Keypoint, to: Keypoint)
    var keypoints: [Keypoint] = []
    var lines: [Line] = []
}

enum PoseEstimationError: Error {
    case failToCreateInputData
    case failToInference
}

protocol PoseEstimator {
    func inference(with pixelBuffer: CVPixelBuffer) -> Result<PoseEstimationOutput, PoseEstimationError>
    func inference(with pixelBuffer: CVPixelBuffer, on targetRect: CGRect?) -> Result<PoseEstimationOutput, PoseEstimationError>
}
