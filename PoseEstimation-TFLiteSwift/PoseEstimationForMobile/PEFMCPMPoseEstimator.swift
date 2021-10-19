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
//  PEFMCPMPoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/22.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo
import UIKit
import TFLiteSwift_Vision

class PEFMCPMPoseEstimator: PoseEstimator {
    
    lazy var imageInterpreter: TFLiteVisionInterpreter? = {
        let interpreterOptions = TFLiteVisionInterpreter.Options(
            modelName: "pefm_cpm",
            normalization: .none
        )
        let imageInterpreter = try? TFLiteVisionInterpreter(options: interpreterOptions)
        return imageInterpreter
    }()
    
    var modelOutput: [TFLiteFlatArray]?
    var delegate: PoseEstimatorDelegate?
    
    func inference(_ uiImage: UIImage, options: PostprocessOptions? = nil) -> Result<PoseEstimationOutput, PoseEstimationError> {
        // initialize
        modelOutput = nil
        
        let result: Result<PoseEstimationOutput, PoseEstimationError>
        if let delegate = delegate {
            // preprocess and preprocss
            var t = CACurrentMediaTime()
            guard let outputs = try? imageInterpreter?.inference(with: uiImage)
                else { return .failure(.failToInference) }
            let inferenceTime = CACurrentMediaTime() - t
            
            // postprocess
            t = CACurrentMediaTime()
            result = Result.success(postprocess(with: outputs))
            let postprocessingTime = CACurrentMediaTime() - t
            delegate.didEndInference(self, preprocessingTime: -1, inferenceTime: inferenceTime, postprocessingTime: postprocessingTime)
        } else {
            // preprocess and inference
            guard let outputs = try? imageInterpreter?.inference(with: uiImage)
                else { return .failure(.failToInference) }
            
            // postprocess
            result = Result.success(postprocess(with: outputs))
        }
        
        return result
    }
    
    func inference(_ pixelBuffer: CVPixelBuffer, options: PostprocessOptions? = nil) -> Result<PoseEstimationOutput, PoseEstimationError> {
        // initialize
        modelOutput = nil
        
        let result: Result<PoseEstimationOutput, PoseEstimationError>
        if let delegate = delegate {
            // preprocess and preprocss
            var t = CACurrentMediaTime()
            guard let outputs = try? imageInterpreter?.inference(with: pixelBuffer)
                else { return .failure(.failToInference) }
            let inferenceTime = CACurrentMediaTime() - t
            
            // postprocess
            t = CACurrentMediaTime()
            result = Result.success(postprocess(with: outputs))
            let postprocessingTime = CACurrentMediaTime() - t
            delegate.didEndInference(self, preprocessingTime: -1, inferenceTime: inferenceTime, postprocessingTime: postprocessingTime)
        } else {
            // preprocess and inference
            guard let outputs = try? imageInterpreter?.inference(with: pixelBuffer)
                else { return .failure(.failToInference) }
            
            // postprocess
            result = Result.success(postprocess(with: outputs))
        }
        
        return result
    }
        
    private func postprocess(with outputs: [TFLiteFlatArray]) -> PoseEstimationOutput {
        return PoseEstimationOutput(outputs: outputs)
    }
    
    func postprocessOnLastOutput(options option: PostprocessOptions) -> PoseEstimationOutput? {
        guard let outputs = modelOutput else { return nil }
        return postprocess(with: outputs)
    }
    
    var partNames: [String] {
        return Output.BodyPart.allCases.map { $0.rawValue }
    }
    
    var pairNames: [String]? {
        return nil
    }
}

private extension PEFMCPMPoseEstimator {
    struct Output {
        struct Heatmap {
            static let width = 96
            static let height = 96
            static let count = BodyPart.allCases.count // 14
        }
        enum BodyPart: String, CaseIterable {
            case TOP = "top"
            case NECK = "neck"
            case RIGHT_SHOULDER = "right shoulder"
            case RIGHT_ELBOW = "right elbow"
            case RIGHT_WRIST = "right wrist"
            case LEFT_SHOULDER = "left shoulder"
            case LEFT_ELBOW = "left elbow"
            case LEFT_WRIST = "left wrist"
            case RIGHT_HIP = "right hip"
            case RIGHT_KNEE = "right knee"
            case RIGHT_ANKLE = "right ankle"
            case LEFT_HIP = "left hip"
            case LEFT_KNEE = "left knee"
            case LEFT_ANKLE = "left ankle"

            static let lines = [
                (from: BodyPart.TOP, to: BodyPart.NECK),
                (from: BodyPart.NECK, to: BodyPart.RIGHT_SHOULDER),
                (from: BodyPart.NECK, to: BodyPart.LEFT_SHOULDER),
                (from: BodyPart.LEFT_WRIST, to: BodyPart.LEFT_ELBOW),
                (from: BodyPart.LEFT_ELBOW, to: BodyPart.LEFT_SHOULDER),
                (from: BodyPart.LEFT_SHOULDER, to: BodyPart.RIGHT_SHOULDER),
                (from: BodyPart.RIGHT_SHOULDER, to: BodyPart.RIGHT_ELBOW),
                (from: BodyPart.RIGHT_ELBOW, to: BodyPart.RIGHT_WRIST),
                (from: BodyPart.LEFT_SHOULDER, to: BodyPart.LEFT_HIP),
                (from: BodyPart.LEFT_HIP, to: BodyPart.RIGHT_HIP),
                (from: BodyPart.RIGHT_HIP, to: BodyPart.RIGHT_SHOULDER),
                (from: BodyPart.LEFT_HIP, to: BodyPart.LEFT_KNEE),
                (from: BodyPart.LEFT_KNEE, to: BodyPart.LEFT_ANKLE),
                (from: BodyPart.RIGHT_HIP, to: BodyPart.RIGHT_KNEE),
                (from: BodyPart.RIGHT_KNEE, to: BodyPart.RIGHT_ANKLE),
            ]
        }
    }
}

private extension PoseEstimationOutput {
    init(outputs: [TFLiteFlatArray]) {
        self.outputs = outputs
        
        let keypoints = convertToKeypoints(from: outputs)
        let lines = makeLines(with: keypoints)
        
        humans = [Human.human2d(human: Human2D(keypoints: keypoints, lines: lines))]
    }
    
    func convertToKeypoints(from outputs: [TFLiteFlatArray]) -> [Keypoint2D] {
        let heatmaps = outputs[0]
        
        // get (col, row)s from heatmaps
        let keypointIndexInfos: [(row: Int, col: Int, val: Float32)] = (0..<PEFMCPMPoseEstimator.Output.Heatmap.count).map { heatmapIndex in
            return heatmaps.argmax(heatmapIndex)
        }
        
        // get points from (col, row)s and offsets
        let keypointInfos: [(point: CGPoint, score: Float)] = keypointIndexInfos.enumerated().map { (index, keypointInfo) in
            // (0.0, 0.0)~(1.0, 1.0)
            let x = (CGFloat(keypointInfo.col) + 0.5) / CGFloat(PEFMCPMPoseEstimator.Output.Heatmap.width)
            let y = (CGFloat(keypointInfo.row) + 0.5) / CGFloat(PEFMCPMPoseEstimator.Output.Heatmap.height)
            let score = Float(keypointInfo.val)
            
            return (point: CGPoint(x: x, y: y), score: score)
        }
        
        return keypointInfos.map { keypointInfo in Keypoint2D(position: keypointInfo.point, score: keypointInfo.score) }
    }
    
    func makeLines(with keypoints: [Keypoint2D]) -> [Human2D.Line2D] {
        var keypointWithBodyPart: [PEFMCPMPoseEstimator.Output.BodyPart: Keypoint2D] = [:]
        PEFMCPMPoseEstimator.Output.BodyPart.allCases.enumerated().forEach { (index, bodyPart) in
            keypointWithBodyPart[bodyPart] = keypoints[index]
        }
        return PEFMCPMPoseEstimator.Output.BodyPart.lines.compactMap { line in
            guard let fromKeypoint = keypointWithBodyPart[line.from],
                let toKeypoint = keypointWithBodyPart[line.to] else { return nil }
            return (from: fromKeypoint, to: toKeypoint)
        }
    }
}
