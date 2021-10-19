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
import TFLiteSwift_Vision

class MovingAverageDoulbe {
    var arr: [Double] = []
    let cnt = 20
    var average: Double { arr.count == 0 ? 0.0 : arr.reduce(0.0, +) / Double(arr.count) }
    func append(_ e: Double) { arr.append(e); while arr.count > cnt { arr.removeFirst() } }
}

class LiteBaseline3DPoseEstimator: PoseEstimator {
    typealias Baseline3DResult = Result<PoseEstimationOutput, PoseEstimationError>
    
    lazy var imageInterpreter: TFLiteVisionInterpreter? = {
        let interpreterOptions = TFLiteVisionInterpreter.Options(
            modelName: "lightweight_baseline_choi",
            accelerator: .cpu,
            inputRankType: .bchw,
            normalization: .pytorchNormalization
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
            result = Result.success(postprocess(with: outputs))
            let postprocessingTime = CACurrentMediaTime() - t
            delegate.didEndInference(self, preprocessingTime: -1, inferenceTime: inferenceTime, postprocessingTime: postprocessingTime)
        } else {
            // preprocss and inference
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
            // preprocss and inference
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
            // preprocss and inference
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

extension LiteBaseline3DPoseEstimator {
    struct Output {
        struct Heatmap {
            static let width = 32
            static let height = 32
            static let depth = 32
            static let count = BodyPart.allCases.count // 18
        }
        
        enum BodyPart: String, CaseIterable {
            case HEAD_TOP = "Head_top"              // 0
            case THORAX = "Thorax"                  // 1
            case RIGHT_SHOULDER = "R_Shoulder"      // 2
            case RIGHT_ELBOW = "R_Elbow"            // 3
            case RIGHT_WRIST = "R_Wrist"            // 4
            case LEFT_SHOULDER = "L_Shoulder"       // 5
            case LEFT_ELBOW = "L_Elbow"             // 6
            case LEFT_WRIST = "L_Wrist"             // 7
            case RIGHT_HIP = "R_Hip"                // 8
            case RIGHT_KNEE = "R_Knee"              // 9
            case RIGHT_ANKLE = "R_Ankle"            // 10
            case LEFT_HIP = "L_Hip"                 // 11
            case LEFT_KNEE = "L_Knee"               // 12
            case LEFT_ANKLE = "L_Ankle"             // 13
            case PELVIS = "Pelvis"                  // 14
            case SPINE = "Spine"                    // 15
            case HEAD = "Head"                      // 16
            case RIGHT_HAND = "R_Hand"              // 17
            case LEFT_HAND = "L_Hand"               // 18
            case RIGHT_TOE = "R_Toe"                // 19
            case LEFT_TOE = "L_Toe"                // 20
            
            static let baselineKeypointIndexes = (2, 5)  // R_Shoulder, L_Shoulder

            static let lines = [
                (from: BodyPart.HEAD_TOP, to: BodyPart.HEAD),
                (from: BodyPart.HEAD, to: BodyPart.THORAX),
                (from: BodyPart.THORAX, to: BodyPart.SPINE),
                (from: BodyPart.SPINE, to: BodyPart.PELVIS),
                (from: BodyPart.PELVIS, to: BodyPart.RIGHT_HIP),
                (from: BodyPart.PELVIS, to: BodyPart.LEFT_HIP),
                (from: BodyPart.RIGHT_HIP, to: BodyPart.RIGHT_KNEE),
                (from: BodyPart.RIGHT_KNEE, to: BodyPart.RIGHT_ANKLE),
                (from: BodyPart.RIGHT_ANKLE, to: BodyPart.RIGHT_TOE),
                (from: BodyPart.RIGHT_ELBOW, to: BodyPart.RIGHT_WRIST),
                (from: BodyPart.LEFT_HIP, to: BodyPart.LEFT_KNEE),
                (from: BodyPart.LEFT_KNEE, to: BodyPart.LEFT_ANKLE),
                (from: BodyPart.LEFT_ANKLE, to: BodyPart.LEFT_TOE),
                (from: BodyPart.THORAX, to: BodyPart.RIGHT_SHOULDER),
                (from: BodyPart.RIGHT_SHOULDER, to: BodyPart.RIGHT_ELBOW),
                (from: BodyPart.RIGHT_ELBOW, to: BodyPart.RIGHT_WRIST),
                (from: BodyPart.RIGHT_WRIST, to: BodyPart.RIGHT_HAND),
                (from: BodyPart.THORAX, to: BodyPart.LEFT_SHOULDER),
                (from: BodyPart.LEFT_SHOULDER, to: BodyPart.LEFT_ELBOW),
                (from: BodyPart.LEFT_ELBOW, to: BodyPart.LEFT_WRIST),
                (from: BodyPart.LEFT_WRIST, to: BodyPart.LEFT_HAND),
            ]
        }
    }
}

private extension PoseEstimationOutput {
    init(outputs: [TFLiteFlatArray]) {
        self.outputs = outputs
        
        let keypoints = convertToKeypoints(from: outputs)
        let lines = makeLines(with: keypoints)
        
        humans = [.human3d(human: Human3D(keypoints: keypoints, lines: lines, baselineKeypointIndexes: LiteBaseline3DPoseEstimator.Output.BodyPart.baselineKeypointIndexes))]
    }
    
    func convertToKeypoints(from outputs: [TFLiteFlatArray]) -> [Keypoint3D] {
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

private extension TFLiteFlatArray {
    
    func softArgmax3d() -> [Keypoint3D] {
        let depth = 32
        let height = dimensions[2]
        let width = dimensions[3]
        let numberOfKeypoints = dimensions[1] / depth
        
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
        
        var xs = array.sum(originalShape: [1, numberOfKeypoints, depth, height, width], targetDimension: [2, 3])
        var ys = array.sum(originalShape: [1, numberOfKeypoints, depth, height, width], targetDimension: [2, 4])
        var zs = array.sum(originalShape: [1, numberOfKeypoints, depth, height, width], targetDimension: [3, 4])
        
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
        
        let summationTargetXYZs = [-1,0,1].reduce([]) { r, xv in
            return r + [-1,0,1].reduce([]) { r, yv in
                return r + [-1,0,1].reduce([]) { r, zv in
                    return r + [(x: xv, y: yv, z: zv)]
                }
            }
        }
        
        return (0..<xs.count).map { kp in
            let x: Int = Int(round(xs[kp] * Float(width)))
            let y: Int = Int(round(ys[kp] * Float(height)))
            let z: Int = Int(round(zs[kp] * Float(depth)))
            let score: Float = summationTargetXYZs.reduce(0.0) {
                let xyz = (x + $1.0, y + $1.1, z + $1.2)
                guard 0 <= xyz.0, xyz.0 < width, 0 <= xyz.1, xyz.1 < height, 0 <= xyz.2, xyz.2 < depth else { return $0 }
                let elementIndex = TensorShape.flatIndex(from: [0, kp, xyz.2, xyz.1, xyz.0], with: [1, kp, depth, height, width])
                let score: Float = array[elementIndex]
                let scoreSclae: Float = ($1.0==0 && $1.1 == 0 && $1.2 == 0 ? 2.0 : 1.0) * 1.5/*1.5 is magic number*/
                return $0 + (score * scoreSclae)
            }
            
            if kp == 0 {
                print(x, y, z, "->", String(format: "%.3f", score))
            }
            return Keypoint3D(x: CGFloat(xs[kp]), y: 1 - CGFloat(ys[kp]), z: CGFloat(zs[kp]), s: max(min(1.0, score), 0.0))
        }
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
