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
import Accelerate
import UIKit
import TFLiteSwift_Vision

class Baseline3DPoseEstimator: PoseEstimator {
    typealias Baseline3DResult = Result<PoseEstimationOutput, PoseEstimationError>
    
    lazy var imageInterpreter: TFLiteVisionInterpreter? = {
        let interpreterOptions = TFLiteVisionInterpreter.Options(
            modelName: "baseline_moon_noS",
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

private extension Baseline3DPoseEstimator {
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

            static let baselineKeypointIndexes = (11, 14)  // L_Shoulder, R_Shoulder
            
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
                (from: BodyPart.RIGHT_KNEE, to: BodyPart.RIGHT_ANKLE),
                (from: BodyPart.PELVIS, to: BodyPart.LEFT_HIP),
                (from: BodyPart.LEFT_HIP, to: BodyPart.LEFT_KNEE),
                (from: BodyPart.LEFT_KNEE, to: BodyPart.LEFT_ANKLE),
            ]
        }
    }
}

private extension PoseEstimationOutput {
    init(outputs: [TFLiteFlatArray]) {
        self.outputs = outputs
        
        let keypoints = convertToKeypoints(from: outputs)
        let lines = makeLines(with: keypoints)
        
        humans = [.human3d(human: Human3D(keypoints: keypoints, lines: lines, baselineKeypointIndexes: Baseline3DPoseEstimator.Output.BodyPart.baselineKeypointIndexes))]
    }
    
    func convertToKeypoints(from outputs: [TFLiteFlatArray]) -> [Keypoint3D] {
        let heatmaps = outputs[0]
        return heatmaps.softArgmax3d().map { Keypoint3D(x: $0.position.x, y: $0.position.y, z: $0.position.z) }
    }
    
    func makeLines(with keypoints: [Keypoint3D]) -> [Human3D.Line3D] {
        var keypointWithBodyPart: [Baseline3DPoseEstimator.Output.BodyPart: Keypoint3D] = [:]
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

private extension TFLiteFlatArray {
    
    func softArgmax3d() -> [Keypoint3D] {
        let depth = 64
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
        
        return (0..<xs.count).map { Keypoint3D(x: CGFloat(xs[$0]), y: 1 - CGFloat(ys[$0]), z: CGFloat(zs[$0])) }
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

extension Array where Element == Float {
    func sum(originalShape: [Int], targetDimension: [Int]) -> [Float] {
        
        let outputShape = originalShape.enumerated()
            .filter { !targetDimension.contains($0.offset) }
            .map { $0.element }
        let totalLength = outputShape.reduce(1) { $0 * $1 }
        let targetShape: [Int] = targetDimension.map { originalShape[$0] }
        var resultArray = Array<Float>(repeating: 0.0, count: totalLength)
        let notTargetDimension: [Int] = (0..<originalShape.count).filter { !targetDimension.contains($0) }
        // let targetTotalLength = targetShape.reduce(1) { $0 * $1 } // with swift
        let sumTargetDimension = targetDimension.enumerated().filter { $0.offset != targetDimension.count - 1 }.map { $0.element } // with accelerate
        let sumTargetShape = targetShape.enumerated() // with accelerate
            .filter { $0.offset != targetShape.count - 1 }
            .map { $0.element }
        let sumTargetLength = sumTargetShape.reduce(1) { $0 * $1 } // with accelerate
        
        let lastDimension = targetDimension[targetDimension.count-1]
        let lastRank = originalShape[lastDimension]
        let lastRankLength = vDSP_Length(lastRank)
        var indexesAsOriginalTensor: [Int] = originalShape.map { _ in return 0 }
        for (flatIndexAsResultTensor, indexesAsResultTensor) in TensorShape(shape: outputShape) {
            indexesAsOriginalTensor = originalShape.map { _ in return 0 }
            indexesAsResultTensor.enumerated().forEach { indexesAsOriginalTensor[notTargetDimension[$0.offset]] = $0.element }
            
            let firstIndexesAsOriginalTensor = indexesAsOriginalTensor
            let secondIndexesAsOriginalTensor = indexesAsOriginalTensor.enumerated().map { $0.offset == lastDimension ? 1 : $0.element }
            let firstFlatIndex = TensorShape.flatIndex(from: firstIndexesAsOriginalTensor, with: originalShape)
            let secondFlatIndex = TensorShape.flatIndex(from: secondIndexesAsOriginalTensor, with: originalShape)
            let strideValue = secondFlatIndex - firstFlatIndex
            let stride = vDSP_Stride(strideValue)
            // print(secondIndexesAsOriginalTensor, firstIndexesAsOriginalTensor)
            // print(secondFlatIndex, "-", firstFlatIndex, "->", strideValue)
            
            // with accelerate
            var sumedValue: Float = 0.0
            for flatIndex in 0..<sumTargetLength {
                let sumTargetIndexes = TensorShape.indexes(from: flatIndex, with: sumTargetShape)
                sumTargetIndexes.enumerated().forEach { indexesAsOriginalTensor[sumTargetDimension[$0.offset]] = $0.element }
                let startingFlatIndex = TensorShape.flatIndex(from: indexesAsOriginalTensor, with: originalShape)
                sumedValue = 0.0
                self.withUnsafeBufferPointer {
                    vDSP_sve($0.baseAddress! + startingFlatIndex, stride, &sumedValue, lastRankLength)
                }
                resultArray[flatIndexAsResultTensor] += sumedValue
            }
            
            /* with swift
            resultArray[flatIndexAsResultTensor] = 0.0
            // sum and assign at flatIndexAsResultTensor
            for flatIndex in 0..<targetTotalLength {
                let targetIndexes = TensorShape.indexes(from: flatIndex, with: targetShape)
                targetIndexes.enumerated().forEach { indexesAsOriginalTensor[targetDimension[$0.offset]] = $0.element }
                resultArray[flatIndexAsResultTensor] += self[TensorShape.flatIndex(from: indexesAsOriginalTensor, with: originalShape)]
            }
             */
        }
        
        return resultArray
    }
}

extension Array where Element == Float {
    static func *=(lhs: inout Array<Float>, rhs: Array<Float>) {
        let stride = vDSP_Stride(1)
        let n = vDSP_Length(lhs.count)
        vDSP_vmul(rhs, stride, lhs, stride, &lhs, stride, n)
    }
}

class TensorShape: Sequence {
    var shape: [Int]
    
    init(shape: [Int]) {
        self.shape = shape
    }
    
    func makeIterator() -> TensorShapeIterator {
        return TensorShapeIterator(shape: shape)
    }
    
    static func indexes(from flatIndex: Int, with shape: [Int]) -> [Int] {
        var flatIndex = flatIndex
        let reversedShape = shape.reversed()
        let reversedIndexes: [Int] = reversedShape.map { rank in
            let result = flatIndex % rank
            flatIndex -= result
            flatIndex /= rank
            return result
        }
        let indexes = reversedIndexes.reversed()
        return Array<Int>(indexes)
    }
    
    static func flatIndex(from indexes: [Int], with shape: [Int]) -> Int {
        var multipleSize = 1
        return zip(indexes, shape).reversed().reduce(0) { (beforeIndex, IndexesAndDimension) in
            let (index, rank) = IndexesAndDimension
            let currentMultipleSize = multipleSize
            multipleSize *= rank
            return beforeIndex + (index * currentMultipleSize)
        }
    }
}

class TensorShapeIterator: IteratorProtocol {
    var shape: [Int]
    var currentFlatIndex: Int
    var length: Int
    
    init(shape: [Int]) {
        self.shape = shape
        self.length = shape.reduce(1) { $0 * $1 }
        self.currentFlatIndex = 0
    }
    func next() -> (Int, [Int])? {
        guard currentFlatIndex < length else { return nil }
        let reversedShape = shape.reversed()
        var flatIndex = currentFlatIndex
        
        let reversedIndexes: [Int] = reversedShape.map { rank in
            let result = flatIndex % rank
            flatIndex = flatIndex / rank
            return result
        }
        let indexes = reversedIndexes.reversed()
        flatIndex = currentFlatIndex
        currentFlatIndex += 1
        
        return (flatIndex, Array<Int>(indexes))
    }
    
    typealias Element = (Int, [Int])
}
