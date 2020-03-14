//
//  PoseNetPoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo

class PoseNetPoseEstimator: PoseEstimator {
    let poseInterpretor = TFLiteImageInterpretor()
    
    func inference(with pixelBuffer: CVPixelBuffer) -> Result<PoseEstimationHeatmaps, PoseEstimationError> {
        guard let tfliteResult = poseInterpretor.predict(with: pixelBuffer) else { return .failure(.commonFail) }
        return .success(PoseEstimationHeatmaps(tfliteResult: tfliteResult))
    }
}
