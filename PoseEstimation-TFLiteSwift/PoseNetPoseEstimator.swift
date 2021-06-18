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
//  PoseNetPoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo
import UIKit

class PoseNetPoseEstimator: PoseEstimator {
    typealias PoseNetResult = Result<PoseEstimationOutput, PoseEstimationError>
    
    lazy var imageInterpreter: TFLiteImageInterpreter = {
        let options = TFLiteImageInterpreter.Options(
            modelName: "posenet_mobilenet_v1_100_257x257_multi_kpt_stripped",
            inputWidth: Input.width,
            inputHeight: Input.height,
            isGrayScale: Input.isGrayScale,
            normalization: Input.normalization
        )
        let imageInterpreter = TFLiteImageInterpreter(options: options)
        return imageInterpreter
    }()
    
    var modelOutput: [TFLiteFlatArray<Float32>]?
    
    func inference(_ input: PoseEstimationInput) -> PoseNetResult {
        
        // initialize
        modelOutput = nil
        
        let result: PoseNetResult
        if let delegate = delegate {
            // preprocss
            var t = CACurrentMediaTime()
            guard let inputData = imageInterpreter.preprocess(with: input)
                else { return .failure(.failToCreateInputData) }
            let preprocessingTime = CACurrentMediaTime() - t
            
            // inference
            t = CACurrentMediaTime()
            guard let outputs = imageInterpreter.inference(with: inputData)
                else { return .failure(.failToInference) }
            let inferenceTime = CACurrentMediaTime() - t
            
            // postprocess
            t = CACurrentMediaTime()
            result = PoseNetResult.success(postprocess(with: outputs))
            let postprocessingTime = CACurrentMediaTime() - t
            delegate.didEndInference(self, preprocessingTime: preprocessingTime, inferenceTime: inferenceTime, postprocessingTime: postprocessingTime)
        } else {
            // preprocss
            guard let inputData = imageInterpreter.preprocess(with: input)
                else { return .failure(.failToCreateInputData) }
            
            // inference
            guard let outputs = imageInterpreter.inference(with: inputData)
                else { return .failure(.failToInference) }
            
            // postprocess
            result = PoseNetResult.success(postprocess(with: outputs))
        }
        
        return result
    }
    
    private func postprocess(with outputs: [TFLiteFlatArray<Float32>]) -> PoseEstimationOutput {
        return PoseEstimationOutput(outputs: outputs)
    }
    
    func postprocessOnLastOutput(options: PostprocessOptions) -> PoseEstimationOutput? {
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

private extension PoseNetPoseEstimator {
    struct Input {
        static let width = 257
        static let height = 257
        static let isGrayScale = false
        static let normalization = TFLiteImageInterpreter.NormalizationOptions.scaledNormalization
    }
    struct Output {
        struct Heatmap {
            static let width = 9
            static let height = 9
            static let count = BodyPart.allCases.count // 14
        }
        struct Offset {
            static let width = 9
            static let height = 9
            static let count = BodyPart.allCases.count * 2 // 34
        }
        enum BodyPart: String, CaseIterable {
            case NOSE = "nose"
            case LEFT_EYE = "left eye"
            case RIGHT_EYE = "right eye"
            case LEFT_EAR = "left ear"
            case RIGHT_EAR = "right ear"
            case LEFT_SHOULDER = "left shoulder"
            case RIGHT_SHOULDER = "right shoulder"
            case LEFT_ELBOW = "left elbow"
            case RIGHT_ELBOW = "right elbow"
            case LEFT_WRIST = "left wrist"
            case RIGHT_WRIST = "right wrist"
            case LEFT_HIP = "left hip"
            case RIGHT_HIP = "right hip"
            case LEFT_KNEE = "left knee"
            case RIGHT_KNEE = "right knee"
            case LEFT_ANKLE = "left ankle"
            case RIGHT_ANKLE = "right ankle"

            static let lines = [
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
    init(outputs: [TFLiteFlatArray<Float32>]) {
        self.outputs = outputs
        
        let keypoints = convertToKeypoints(from: outputs)
        let lines = makeLines(with: keypoints)
        
        humans = [Human.human2d(human: Human2D(keypoints: keypoints, lines: lines))]
    }
    
    func convertToKeypoints(from outputs: [TFLiteFlatArray<Float32>]) -> [Keypoint2D] {
        let heatmaps = outputs[0]
        let offsets = outputs[1]
        
        // get (col, row)s from heatmaps
        let keypointIndexInfos: [(row: Int, col: Int, val: Float32)] = (0..<PoseNetPoseEstimator.Output.Heatmap.count).map { heatmapIndex in
            return heatmaps.argmax(heatmapIndex)
        }
        
        // get points from (col, row)s and offsets
        let keypointInfos: [(point: CGPoint, score: Float)] = keypointIndexInfos.enumerated().map { (index, keypointInfo) in
            // (0.0, 0.0)~(1.0, 1.0)
            let xNaive = (CGFloat(keypointInfo.col)) / CGFloat(PoseNetPoseEstimator.Output.Heatmap.width - 1)
            let yNaive = (CGFloat(keypointInfo.row)) / CGFloat(PoseNetPoseEstimator.Output.Heatmap.height - 1)
            
            // (0.0, 0.0)~(Input.width, Input.height)
            let xOffset = offsets[0, keypointInfo.row, keypointInfo.col, index + PoseNetPoseEstimator.Output.Heatmap.count]
            let yOffset = offsets[0, keypointInfo.row, keypointInfo.col, index]
            
            // (0.0, 0.0)~(Input.width, Input.height)
            let xScaledInput = xNaive * CGFloat(PoseNetPoseEstimator.Input.width) + CGFloat(xOffset)
            let yScaledInput = yNaive * CGFloat(PoseNetPoseEstimator.Input.height) + CGFloat(yOffset)
            
            // (0.0, 0.0)~(1.0, 1.0)
            let x = xScaledInput / CGFloat(PoseNetPoseEstimator.Input.width)
            let y = yScaledInput / CGFloat(PoseNetPoseEstimator.Input.height)
            let score = Float(keypointInfo.val)
            
            return (point: CGPoint(x: x, y: y), score: score)
        }
        
        return keypointInfos.map { keypointInfo in Keypoint2D(position: keypointInfo.point, score: keypointInfo.score) }
    }
    
    func makeLines(with keypoints: [Keypoint2D]) -> [Human2D.Line2D] {
        var keypointWithBodyPart: [PoseNetPoseEstimator.Output.BodyPart: Keypoint2D] = [:]
        PoseNetPoseEstimator.Output.BodyPart.allCases.enumerated().forEach { (index, bodyPart) in
            keypointWithBodyPart[bodyPart] = keypoints[index]
        }
        return PoseNetPoseEstimator.Output.BodyPart.lines.compactMap { line in
            guard let fromKeypoint = keypointWithBodyPart[line.from],
                let toKeypoint = keypointWithBodyPart[line.to] else { return nil }
            return (from: fromKeypoint, to: toKeypoint)
        }
    }
}
