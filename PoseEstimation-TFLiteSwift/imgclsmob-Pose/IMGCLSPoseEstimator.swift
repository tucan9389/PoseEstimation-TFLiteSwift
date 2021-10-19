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
//  IMGCLSPoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/05/23.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo
import UIKit
import TFLiteSwift_Vision

class IMGCLSPoseEstimator: PoseEstimator {
    
    lazy var imageInterpreter: TFLiteVisionInterpreter? = {
        let interpreterOptions = TFLiteVisionInterpreter.Options(
            modelName: MLModelName.simplePoseResnet18.rawValue,
            normalization: .scaled(from: 0.0, to: 1.0)
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
            // preprocss and inference
            var t = CACurrentMediaTime()
            guard let outputs = try? imageInterpreter?.inference(with: uiImage)
                else { return .failure(.failToInference) }
            let inferenceTime = CACurrentMediaTime() - t
            
            // postprocess
            t = CACurrentMediaTime()
            result = Result.success(postprocess(outputs, with: options))
            let postprocessingTime = CACurrentMediaTime() - t
            delegate.didEndInference(self, preprocessingTime: -1, inferenceTime: inferenceTime, postprocessingTime: postprocessingTime)
        } else {
            // preprocss and inference
            guard let outputs = try? imageInterpreter?.inference(with: uiImage)
                else { return .failure(.failToInference) }
            
            // postprocess
            result = Result.success(postprocess(outputs, with: options))
        }
        
        return result
    }
    
    func inference(_ pixelBuffer: CVPixelBuffer, options: PostprocessOptions? = nil) -> Result<PoseEstimationOutput, PoseEstimationError> {
        
        // initialize
        modelOutput = nil
        
        let result: Result<PoseEstimationOutput, PoseEstimationError>
        if let delegate = delegate {
            // preprocss and inference
            var t = CACurrentMediaTime()
            guard let outputs = try? imageInterpreter?.inference(with: pixelBuffer)
                else { return .failure(.failToInference) }
            let inferenceTime = CACurrentMediaTime() - t
            
            // postprocess
            t = CACurrentMediaTime()
            result = Result.success(postprocess(outputs, with: options))
            let postprocessingTime = CACurrentMediaTime() - t
            delegate.didEndInference(self, preprocessingTime: -1, inferenceTime: inferenceTime, postprocessingTime: postprocessingTime)
        } else {
            // preprocss and inference
            guard let outputs = try? imageInterpreter?.inference(with: pixelBuffer)
                else { return .failure(.failToInference) }
            
            // postprocess
            result = Result.success(postprocess(outputs, with: options))
        }
        
        return result
    }
    
    private func postprocess(_ outputs: [TFLiteFlatArray], with options: PostprocessOptions?) -> PoseEstimationOutput {
        return PoseEstimationOutput(outputs: outputs, postprocessOptions: options)
    }
    
    func postprocessOnLastOutput(options: PostprocessOptions) -> PoseEstimationOutput? {
        guard let outputs = modelOutput else { return nil }
        return postprocess(outputs, with: options)
    }
    
    var partNames: [String] {
        return Output.BodyPart.allCases.map { $0.rawValue }
    }
    
    var pairNames: [String]? {
        return nil
    }
}

extension IMGCLSPoseEstimator {
    enum MLModelName: String {
//        case alphaPose = "alphapose_fastseresnet101b_coco"
//        case simplePoseMobileNet = "simplepose_mobile_mobilenet_w1_coco"
//        case simplePoseMobileNetV2 = "simplepose_mobile_mobilenetv2b_w1_coco"
//        case simplePoseMobileNetV3Small = "simplepose_mobile_mobilenetv3_small_w1_coco"
//        case simplePoseMobileNetV3Large = "simplepose_mobile_mobilenetv3_large_w1_coco"
//        case simplePoseMobileResnet18 = "simplepose_mobile_resnet18_coco"
//        case simplePoseMobileResnet50 = "simplepose_mobile_resnet50b_coco"
        case simplePoseResnet18 = "simplepose_resnet18_coco"
        case simplePoseResnet50 = "simplepose_resnet50b_coco"
        case simplePoseResnet101 = "simplepose_resnet101b_coco"
        case simplePoseResnet152 = "simplepose_resnet152b_coco"
        case simplePoseResnetA101 = "simplepose_resneta101b_coco"
        case simplePoseResnetA152 = "simplepose_resneta152b_coco"
    }
}

private extension IMGCLSPoseEstimator {
    struct Output {
        struct Heatmap {
            static let width = 56
            static let height = 56
            static let count = BodyPart.allCases.count // 17
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
    init(outputs: [TFLiteFlatArray], postprocessOptions: PostprocessOptions?) {
        self.outputs = outputs
        
        let human = parseSinglePerson(outputs,
                                      partIndex: postprocessOptions?.bodyPart,
                                      partThreshold: postprocessOptions?.partThreshold)
        humans = [.human2d(human: human)]
    }
    
    func parseSinglePerson(_ outputs: [TFLiteFlatArray], partIndex: Int?, partThreshold: Float?) -> Human2D {
        let output = outputs[0]
        
        // get (col, row)s from heatmaps
        let keypointIndexInfos: [(row: Int, col: Int, val: Float32)] = (0..<IMGCLSPoseEstimator.Output.Heatmap.count).map { heatmapIndex in
            return output.argmax(heatmapIndex)
        }
        
        // get points from (col, row)s and offsets
        let keypointInfos: [(point: CGPoint, score: Float)] = keypointIndexInfos.enumerated().map { (index, keypointInfo) in
            // (0.0, 0.0)~(1.0, 1.0)
            let x = (CGFloat(keypointInfo.col) + 0.5) / CGFloat(IMGCLSPoseEstimator.Output.Heatmap.width)
            let y = (CGFloat(keypointInfo.row) + 0.5) / CGFloat(IMGCLSPoseEstimator.Output.Heatmap.height)
            let score = Float(keypointInfo.val)
            
            return (point: CGPoint(x: x, y: y), score: score)
        }
        
        let keypoints: [Keypoint2D?] = keypointInfos
            .map { keypointInfo -> Keypoint2D? in Keypoint2D(position: keypointInfo.point, score: keypointInfo.score) }
            .map { keypointInfo -> Keypoint2D? in
                guard let score = keypointInfo?.score, let partThreshold = partThreshold else { return keypointInfo }
                return (score > partThreshold) ? keypointInfo : nil
        }
        
        // lines
        var keypointWithBodyPart: [IMGCLSPoseEstimator.Output.BodyPart: Keypoint2D] = [:]
        IMGCLSPoseEstimator.Output.BodyPart.allCases.enumerated().forEach { (index, bodyPart) in
            keypointWithBodyPart[bodyPart] = keypoints[index]
        }
        let lines: [Human2D.Line2D] = IMGCLSPoseEstimator.Output.BodyPart.lines.compactMap { line in
            guard let fromKeypoint = keypointWithBodyPart[line.from],
                let toKeypoint = keypointWithBodyPart[line.to] else { return nil }
            return (from: fromKeypoint, to: toKeypoint)
        }
        
        return Human2D(keypoints: keypoints, lines: lines)
    }
}
