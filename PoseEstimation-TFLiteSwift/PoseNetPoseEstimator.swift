//
//  PoseNetPoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo

class PoseNetPoseEstimator: PoseEstimator {
    lazy var imageInterpreter: TFLiteImageInterpreter = {
        let options = TFLiteImageInterpreter.Options(
            modelName: "posenet_mobilenet_v1_100_257x257_multi_kpt_stripped",
            inputWidth: 257,
            inputHeight: 257
        )
        let imageInterpreter = TFLiteImageInterpreter(options: options)
        return imageInterpreter
    }()
    
    func inference(with pixelBuffer: CVPixelBuffer) -> Result<PoseEstimationHeatmaps, PoseEstimationError> {
        // preprocss
        guard let inputData = imageInterpreter.preprocessMiddleSquareArea(with: pixelBuffer) else { return .failure(.failToCreateInputData) }
        // inference
        guard let tfliteResult = imageInterpreter.inference(with: inputData) else { return .failure(.failToInference) }
        // postprocess
        let result = postprocess(with: tfliteResult)
        
        return result
    }
    
    private func postprocess(with tfliteResult: TFLiteResult) -> Result<PoseEstimationHeatmaps, PoseEstimationError> {
        // <#TODO#>
        return .success(PoseEstimationHeatmaps(tfliteResult: tfliteResult))
    }
}
