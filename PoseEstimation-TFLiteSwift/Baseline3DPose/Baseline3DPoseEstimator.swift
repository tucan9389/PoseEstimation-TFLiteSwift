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
//  Baseline3DPoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/22.
//  Copyright © 2021 Doyoung Gwak. All rights reserved.
//

import CoreVideo

class Baseline3DPoseEstimator: PoseEstimator {
    typealias PEFMCPMResult = Result<PoseEstimationOutput, PoseEstimationError>
    
    lazy var imageInterpreter: TFLiteImageInterpreter = {
        let options = TFLiteImageInterpreter.Options(
            modelName: "baseline_moon_noS",
            inputWidth: Input.width,
            inputHeight: Input.height,
            inputRankType: Input.inputRankType,
            isGrayScale: Input.isGrayScale,
            normalization: Input.normalization
        )
        let imageInterpreter = TFLiteImageInterpreter(options: options)
        return imageInterpreter
    }()
    
    var modelOutput: [TFLiteFlatArray<Float32>]?
    
    func inference(_ input: PoseEstimationInput) -> PEFMCPMResult {
        
        // initialize
        modelOutput = nil
        
        // preprocss
        guard let inputData = imageInterpreter.preprocess(with: input)
            else { return .failure(.failToCreateInputData) }
        
        // inference
        guard let outputs = imageInterpreter.inference(with: inputData)
            else { return .failure(.failToInference) }
        
        // postprocess
        let result = PEFMCPMResult.success(postprocess(with: outputs))
        
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

private extension Baseline3DPoseEstimator {
    struct Input {
        static let width = 256
        static let height = 256
        static let inputRankType = TFLiteImageInterpreter.RankType.bchw
        static let isGrayScale = false
        static let normalization = TFLiteImageInterpreter.NormalizationOptions.pytorchNormalization
    }
    struct Output {
        struct Heatmap {
            static let width = 64
            static let height = 64
            static let depth = 64
            static let count = BodyPart.allCases.count // 18
        }
        enum BodyPart: String, CaseIterable {
            case PELVIS = "Pelvis"          // 0
            case RIGHT_HIP = "R_Hip"        // 1
            case RIGHT_KNEE = "R_Knee"      // 2
            case RIGHT_ANKLE = "R_Ankle"    // 3
            case LEFT_HIP = "L_Hip"         // 4
            case LEFT_KNEE = "L_Knee"       // 5
            case LEFT_ANKLE = "L_Ankle"     // 6
            case TORSO = "Torso"            // 7
            case NECK = "Neck"              // 8
            case NOSE = "Nose"              // 9
            case HEAD = "Head"              // 10
            case LEFT_SHOULDER = "L_Shoulder"   // 11
            case LEFT_ELBOW = "L_Elbow"         // 12
            case LEFT_WRIST = "L_Wrist"         // 13
            case RIGHT_SHOULDER = "R_Shoulder"  // 14
            case RIGHT_ELBOW = "R_Elbow"        // 15
            case RIGHT_WRIST = "R_Wrist"        // 16
            case THORAX = "Thorax"              // 17

            static let lines = [
                (from: BodyPart.PELVIS, to: BodyPart.TORSO),
                (from: BodyPart.TORSO, to: BodyPart.NECK),
                (from: BodyPart.NECK, to: BodyPart.NOSE),
                (from: BodyPart.NOSE, to: BodyPart.HEAD),
                (from: BodyPart.NECK, to: BodyPart.LEFT_SHOULDER),
                (from: BodyPart.LEFT_SHOULDER, to: BodyPart.LEFT_ELBOW),
                (from: BodyPart.LEFT_ELBOW, to: BodyPart.LEFT_WRIST),
                (from: BodyPart.NECK, to: BodyPart.RIGHT_SHOULDER),
                (from: BodyPart.RIGHT_SHOULDER, to: BodyPart.RIGHT_ELBOW),
                (from: BodyPart.RIGHT_ELBOW, to: BodyPart.RIGHT_WRIST),
                (from: BodyPart.PELVIS, to: BodyPart.RIGHT_HIP),
                (from: BodyPart.RIGHT_HIP, to: BodyPart.RIGHT_KNEE),
                (from: BodyPart.PELVIS, to: BodyPart.LEFT_HIP),
                (from: BodyPart.LEFT_HIP, to: BodyPart.LEFT_KNEE),
                (from: BodyPart.LEFT_HIP, to: BodyPart.LEFT_KNEE),
            ]
        }
    }
}

private extension PoseEstimationOutput {
    init(outputs: [TFLiteFlatArray<Float32>]) {
        self.outputs = outputs
        
        let keypoints = convertToKeypoints(from: outputs)
        let lines = makeLines(with: keypoints)
        
        humans = [Human(keypoints: keypoints, lines: lines)]
    }
    
    func convertToKeypoints(from outputs: [TFLiteFlatArray<Float32>]) -> [Keypoint] {
        let heatmaps = outputs[0]
        
        // get (col, row)s from heatmaps
        let keypointIndexInfos: [(row: Int, col: Int, dep: Int, val: Float32)] = (0..<Baseline3DPoseEstimator.Output.Heatmap.count).map { heatmapIndex in
            return heatmaps.argmax3d(heatmapIndex)
        }
        
        // get points from (col, row)s and offsets
        let keypointInfos: [(point: CGPoint, score: Float)] = keypointIndexInfos.enumerated().map { (index, keypointInfo) in
            // (0.0, 0.0)~(1.0, 1.0)
            let x = (CGFloat(keypointInfo.col) + 0.5) / CGFloat(Baseline3DPoseEstimator.Output.Heatmap.width)
            let y = (CGFloat(keypointInfo.row) + 0.5) / CGFloat(Baseline3DPoseEstimator.Output.Heatmap.height)
            let z = (CGFloat(keypointInfo.dep) + 0.5) / CGFloat(Baseline3DPoseEstimator.Output.Heatmap.depth)
            let score = Float(keypointInfo.val)
            
            return (point: CGPoint(x: x, y: y), score: score)
        }
        
        return keypointInfos.map { keypointInfo in Keypoint(position: keypointInfo.point, score: keypointInfo.score) }
    }
    
    func makeLines(with keypoints: [Keypoint]) -> [Human.Line] {
        var keypointWithBodyPart: [Baseline3DPoseEstimator.Output.BodyPart: Keypoint] = [:]
        Baseline3DPoseEstimator.Output.BodyPart.allCases.enumerated().forEach { (index, bodyPart) in
            keypointWithBodyPart[bodyPart] = keypoints[index]
        }
        return Baseline3DPoseEstimator.Output.BodyPart.lines.compactMap { line in
            guard let fromKeypoint = keypointWithBodyPart[line.from],
                let toKeypoint = keypointWithBodyPart[line.to] else { return nil }
            return (from: fromKeypoint, to: toKeypoint)
        }
    }
}

extension TFLiteFlatArray where Element==Float32 {
    func argmax3d(_ heatmapIndex: Int) -> (row: Int, col: Int, dep: Int, val: Element) {
        let depth = 64
        let height = dimensions[2]
        let width = dimensions[3]
        var maxInfo = (row: 0, col: 0, dep: 0, val: self[heatmap: 0, (heatmapIndex * height) + 0, 0, 0])
        for row in 0..<height {
            for col in 0..<width {
                for dep in 0..<depth {
                    if self[heatmap: 0, (heatmapIndex * height) + dep, row, col] > maxInfo.val {
                        maxInfo = (row: row, col: col, dep: dep, val: self[0, (heatmapIndex * height) + dep, row, col])
                    }
                }
            }
        }
        return maxInfo
    }
}
