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
//  LiteBaseline3DPoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/22.
//  Copyright © 2021 Doyoung Gwak. All rights reserved.
//

import CoreVideo
import Accelerate
import UIKit

class LiteBaseline3DPoseEstimator: PoseEstimator {
    typealias LiteBaseline3DResult = Result<PoseEstimationOutput, PoseEstimationError>
    
    lazy var imageInterpreter: TFLiteImageInterpreter = {
        let options = TFLiteImageInterpreter.Options(
            modelName: "mhp_litebaseline_MuCo_64",
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
    
    func inference(_ input: PoseEstimationInput) -> LiteBaseline3DResult {
        
        // initialize
        modelOutput = nil
        
        // preprocss
        // var t = CACurrentMediaTime()
        guard let inputData = imageInterpreter.preprocess(with: input)
            else { return .failure(.failToCreateInputData) }
        // print("preprocess time :\(CACurrentMediaTime() - t)")
        
        // inference
        // t = CACurrentMediaTime()
        guard let outputs = imageInterpreter.inference(with: inputData)
            else { return .failure(.failToInference) }
        // print("inference time  :\(CACurrentMediaTime() - t)")
        
        // postprocess
        // t = CACurrentMediaTime()
        let result = LiteBaseline3DResult.success(postprocess(with: outputs))
        // print("postprocess time:\(CACurrentMediaTime() - t)")
        
        print()
        
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

private extension LiteBaseline3DPoseEstimator {
    struct Input {
        static let width = 256
        static let height = 256
        static let inputRankType = TFLiteImageInterpreter.RankType.bwhc
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
            case Head_top = "Head_top"          // 0
            case Thorax = "Thorax"              // 1
            case R_Shoulder = "R_Shoulder"      // 2
            case R_Elbow = "R_Elbow"            // 3
            case R_Wrist = "R_Wrist"            // 4
            case L_Shoulder = "L_Shoulder"      // 5
            case L_Elbow = "L_Elbow"            // 6
            case L_Wrist = "L_Wrist"            // 7
            case R_Hip = "R_Hip"                // 8
            case R_Knee = "R_Knee"              // 9
            case R_Ankle = "R_Ankle"            // 10
            case L_Hip = "L_Hip"                // 11
            case L_Knee = "L_Knee"              // 12
            case L_Ankle = "L_Ankle"            // 13
            case Pelvis = "Pelvis"              // 14
            case Spine = "Spine"                // 15
            case Head = "Head"                  // 16
            case R_Hand = "R_Hand"              // 17
            case L_Hand = "L_Hand"              // 18
            case R_Toe = "R_Toe"                // 19
            case L_Toe = "L_Toe"                // 20
            
            static let baselineKeypointIndexes = (2, 5)  // R_Shoulder, L_Shoulder

            static let lines = [
                (from: BodyPart.Head_top, to: BodyPart.Head),
                (from: BodyPart.Head, to: BodyPart.Thorax),
                (from: BodyPart.Thorax, to: BodyPart.Spine),
                (from: BodyPart.Spine, to: BodyPart.Pelvis),
                (from: BodyPart.Pelvis, to: BodyPart.R_Hip),
                (from: BodyPart.Pelvis, to: BodyPart.L_Hip),
                (from: BodyPart.R_Hip, to: BodyPart.R_Knee),
                (from: BodyPart.R_Knee, to: BodyPart.R_Ankle),
                (from: BodyPart.R_Ankle, to: BodyPart.R_Toe),
                (from: BodyPart.L_Hip, to: BodyPart.L_Knee),
                (from: BodyPart.L_Knee, to: BodyPart.L_Ankle),
                (from: BodyPart.L_Ankle, to: BodyPart.L_Toe),
                (from: BodyPart.Thorax, to: BodyPart.R_Shoulder),
                (from: BodyPart.R_Shoulder, to: BodyPart.R_Elbow),
                (from: BodyPart.R_Elbow, to: BodyPart.R_Wrist),
                (from: BodyPart.R_Wrist, to: BodyPart.R_Hand),
                (from: BodyPart.Thorax, to: BodyPart.L_Shoulder),
                (from: BodyPart.L_Shoulder, to: BodyPart.L_Elbow),
                (from: BodyPart.L_Elbow, to: BodyPart.L_Wrist),
                (from: BodyPart.L_Wrist, to: BodyPart.L_Hand),
            ]
        }
    }
}

private extension PoseEstimationOutput {
    init(outputs: [TFLiteFlatArray<Float32>]) {
        self.outputs = outputs
        
        let keypoints = convertToKeypoints(from: outputs)
        let lines = makeLines(with: keypoints)
        
        humans = [.human3d(human: Human3D(keypoints: keypoints, lines: lines, baselineKeypointIndexes: LiteBaseline3DPoseEstimator.Output.BodyPart.baselineKeypointIndexes))]
    }
    
    func convertToKeypoints(from outputs: [TFLiteFlatArray<Float32>]) -> [Keypoint3D] {
        let heatmaps = outputs[0]
        return heatmaps.softArgmax3d().map { Keypoint3D(x: $0.position.x, y: $0.position.y, z: $0.position.z) }
    }
    
    func makeLines(with keypoints: [Keypoint3D]) -> [Human3D.Line3D] {
        var keypointWithBodyPart: [LiteBaseline3DPoseEstimator.Output.BodyPart: Keypoint3D] = [:]
        LiteBaseline3DPoseEstimator.Output.BodyPart.allCases.enumerated().forEach { (index, bodyPart) in
            keypointWithBodyPart[bodyPart] = keypoints[index]
        }
        return LiteBaseline3DPoseEstimator.Output.BodyPart.lines.compactMap { line in
            guard let fromKeypoint = keypointWithBodyPart[line.from],
                let toKeypoint = keypointWithBodyPart[line.to] else { return nil }
            return (from: fromKeypoint, to: toKeypoint)
        }
    }
}

private extension TFLiteFlatArray where Element==Float32 {
    
    func softArgmax3d() -> [Keypoint3D] {
        let depth = LiteBaseline3DPoseEstimator.Output.Heatmap.depth
        let height = dimensions[2]
        let width = dimensions[1]
        let numberOfKeypoints = dimensions[3] / depth
        
        // softmax per keypoints
        for keypointIndex in 0..<numberOfKeypoints {
            let startIndex = TensorShape.flatIndex(from: [0, keypointIndex + 0, 0, 0, 0], with: [1, keypointIndex, depth, height, width])
            let endIndex   = TensorShape.flatIndex(from: [0, keypointIndex + 1, 0, 0, 0], with: [1, keypointIndex, depth, height, width])
            let heatmapsAtKeypoint = Array(array[startIndex..<endIndex])
            array.replaceSubrange(startIndex..<endIndex, with: Self.softmax(heatmapsAtKeypoint))
        }
        
        // print(array.count)
        // print(array[0..<(numberOfKeypoints*depth)])
        
        // sum each
        // (1, 18, 64, 64, 64)
        // ex) (18, 64, 12)
        
//        var xs = array.sum(originalShape: [1, numberOfKeypoints, depth, height, width], targetDimension: [2, 3])
//        var ys = array.sum(originalShape: [1, numberOfKeypoints, depth, height, width], targetDimension: [2, 4])
//        var zs = array.sum(originalShape: [1, numberOfKeypoints, depth, height, width], targetDimension: [3, 4])
        
        var xs = array.sum(originalShape: [1, width, height, depth, numberOfKeypoints], targetDimension: [2, 3])
        var ys = array.sum(originalShape: [1, width, height, depth, numberOfKeypoints], targetDimension: [1, 3])
        var zs = array.sum(originalShape: [1, width, height, depth, numberOfKeypoints], targetDimension: [1, 2])
        
        // print(xs)
        // print(xs.count)
        
        let rangeWidthFloat  = (0..<(numberOfKeypoints * width)).map { Float($0 % width) }
        let rangeHeightFloat = (0..<(numberOfKeypoints * height)).map { Float($0 % height) }
        let rangeDepthFloat  = (0..<(numberOfKeypoints * depth)).map { Float($0 % depth) }
        
        xs *= rangeWidthFloat
        ys *= rangeHeightFloat
        zs *= rangeDepthFloat
        
        xs = xs.sum(originalShape: [1, numberOfKeypoints, width], targetDimension: [2])
        ys = ys.sum(originalShape: [1, numberOfKeypoints, height], targetDimension: [2])
        zs = zs.sum(originalShape: [1, numberOfKeypoints, depth], targetDimension: [2])
        
        xs = xs.map { ($0 - 0.5) / Float(width)  }
        ys = ys.map { ($0 - 0.5) / Float(height) }
        zs = zs.map { ($0 - 0.5) / Float(depth) }
        
        // print("x:", xs)
        // print("y:", ys)
        // print("z:", zs)
        
        return (0..<xs.count).map { Keypoint3D(x: CGFloat(xs[$0]), y: CGFloat(ys[$0]), z: CGFloat(zs[$0])) }
    }
    
    /**
     Computes the "softmax" function over an array.
     Based on code from https://github.com/nikolaypavlov/MLPNeuralNet/
     This is what softmax looks like in "pseudocode" (actually using Python
     and numpy):
     x -= np.max(x)
     exp_scores = np.exp(x)
     softmax = exp_scores / np.sum(exp_scores)
     First we shift the values of x so that the highest value in the array is 0.
     This ensures numerical stability with the exponents, so they don't blow up.
     */
    static func softmax(_ x: [Float]) -> [Float] {
        var x = x
        let len = vDSP_Length(x.count)
        
        // Find the maximum value in the input array.
        var max: Float = 0
        vDSP_maxv(x, 1, &max, len)
        
        // Subtract the maximum from all the elements in the array.
        // Now the highest value in the array is 0.
        max = -max
        vDSP_vsadd(x, 1, &max, &x, 1, len)
        
        // Exponentiate all the elements in the array.
        var count = Int32(x.count)
        vvexpf(&x, x, &count)
        
        // Compute the sum of all exponentiated values.
        var sum: Float = 0
        vDSP_sve(x, 1, &sum, len)
        
        // Divide each element by the sum. This normalizes the array contents
        // so that they all add up to 1.
        vDSP_vsdiv(x, 1, &sum, &x, 1, len)
        
        return x
    }
    
    
}
