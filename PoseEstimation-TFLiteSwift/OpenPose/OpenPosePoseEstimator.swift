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
//  OpenPosePoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/04/04.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreGraphics

class OpenPosePoseEstimator: PoseEstimator {
    typealias OpenPoseResult = Result<PoseEstimationOutput, PoseEstimationError>
    
    lazy var imageInterpreter: TFLiteImageInterpreter = {
        let options = TFLiteImageInterpreter.Options(
            modelName: "openpose_ildoonet",
            inputWidth: Input.width,
            inputHeight: Input.height,
            isGrayScale: Input.isGrayScale,
            isNormalized: Input.isNormalized
        )
        let imageInterpreter = TFLiteImageInterpreter(options: options)
        return imageInterpreter
    }()
    
    func inference(with input: PoseEstimationInput) -> OpenPoseResult {
        // preprocss
        guard let inputData = imageInterpreter.preprocess(with: input)
            else { return .failure(.failToCreateInputData) }
        // inference
        guard let outputs = imageInterpreter.inference(with: inputData)
            else { return .failure(.failToInference) }
        // postprocess
        let result = postprocess(with: outputs)
        
        return result
    }
    
    private func postprocess(with outputs: [TFLiteFlatArray<Float32>]) -> OpenPoseResult {
        return .success(PoseEstimationOutput(outputs: outputs))
    }
}

private extension OpenPosePoseEstimator {
    struct Input {
        static let width = 432
        static let height = 368
        static let isGrayScale = false
        static let isNormalized = false
    }
    struct Output {
        struct ConfidenceMap { // similar to Heatmap
            static let width = 54
            static let height = 46
            static let count = BodyPart.allCases.count // 19
        }
        struct AffinityField {
            static let width = 54
            static let height = 46
            static let count = BodyPart.allCases.count * 2 // 38
        }
        enum BodyPart: String, CaseIterable {
            case NOSE = "nose" // 0
            case NECK = "Neck" // 1
            case RIGHT_SHOULDER = "RShoulder" // 2
            case RIGHT_ELBOW = "RElbow" // 3
            case RIGHT_WRIST = "RWrist" // 4
            case LEFT_SHOULDER = "LShoulder" // 5
            case LEFT_ELBOW = "LElbow" // 6
            case LEFT_WRIST = "LWrist" // 7
            case RIGHT_HIP = "RHip" // 8
            case RIGHT_KNEE = "RKnee" // 9
            case RIGHT_ANKLE = "RAnkle" // 10
            case LEFT_HIP = "LHip" // 11
            case LEFT_KNEE = "LKnee" // 12
            case LEFT_ANKLE = "LAnkle" // 13
            case RIGHT_EYE = "REye" // 14
            case LEFT_EYE = "LEye" // 15
            case RIGHT_EAR = "REar" // 16
            case LEFT_EAR = "LEar" // 17
            case BACKGROUND = "Background" // 18

            // (1, 2), (1, 5), (2, 3), (3, 4), (5, 6), (6, 7), (1, 8), (8, 9), (9, 10), (1, 11),
            // (11, 12), (12, 13), (1, 0), (0, 14), (14, 16), (0, 15), (15, 17), (2, 16), (5, 17)
            static let lines = [
                (from: BodyPart.NECK, to: BodyPart.RIGHT_SHOULDER),
                (from: BodyPart.NECK, to: BodyPart.LEFT_SHOULDER),
                (from: BodyPart.RIGHT_SHOULDER, to: BodyPart.RIGHT_ELBOW),
                (from: BodyPart.RIGHT_ELBOW, to: BodyPart.RIGHT_WRIST),
                (from: BodyPart.LEFT_SHOULDER, to: BodyPart.LEFT_ELBOW),
                (from: BodyPart.LEFT_ELBOW, to: BodyPart.LEFT_WRIST),
                (from: BodyPart.NECK, to: BodyPart.RIGHT_HIP),
                (from: BodyPart.RIGHT_HIP, to: BodyPart.RIGHT_KNEE),
                (from: BodyPart.RIGHT_KNEE, to: BodyPart.RIGHT_ANKLE),
                (from: BodyPart.NECK, to: BodyPart.LEFT_HIP),
                
                (from: BodyPart.LEFT_HIP, to: BodyPart.LEFT_KNEE),
                (from: BodyPart.LEFT_KNEE, to: BodyPart.LEFT_ANKLE),
                (from: BodyPart.NECK, to: BodyPart.NOSE),
                (from: BodyPart.NOSE, to: BodyPart.RIGHT_EYE),
                (from: BodyPart.RIGHT_EYE, to: BodyPart.RIGHT_EAR),
                (from: BodyPart.NOSE, to: BodyPart.LEFT_EYE),
                (from: BodyPart.LEFT_EYE, to: BodyPart.LEFT_EAR),
                (from: BodyPart.RIGHT_SHOULDER, to: BodyPart.RIGHT_EAR),
                (from: BodyPart.LEFT_SHOULDER, to: BodyPart.LEFT_EAR),
            ]
        }
    }
}

private extension PoseEstimationOutput {
    init(outputs: [TFLiteFlatArray<Float32>]) {
        let keypoints = convertToKeypoints(from: outputs)
        let lines = makeLines(with: keypoints)
        
        self.keypoints = keypoints
        self.lines = lines
    }
    
    func convertToKeypoints(from outputs: [TFLiteFlatArray<Float32>]) -> [Keypoint] {
        let output = outputs[0]
        
        // get (col, row)s from heatmaps
        let keypointIndexInfos: [(row: Int, col: Int, val: Float32)] = (0..<OpenPosePoseEstimator.Output.ConfidenceMap.count).map { heatmapIndex in
            var maxInfo = (row: 0, col: 0, val: output[heatmap: 0, 0, 0, heatmapIndex])
            for row in 0..<OpenPosePoseEstimator.Output.ConfidenceMap.height {
                for col in 0..<OpenPosePoseEstimator.Output.ConfidenceMap.width {
                    if output[heatmap: 0, row, col, heatmapIndex] > maxInfo.val {
                        maxInfo = (row: row, col: col, val: output[0, row, col, heatmapIndex])
                    }
                }
            }
            return maxInfo
        }
        
        // get points from (col, row)s and offsets
        let keypointInfos: [(point: CGPoint, score: Float)] = keypointIndexInfos.enumerated().map { (index, keypointInfo) in
            // (0.0, 0.0)~(1.0, 1.0)
            let x = (CGFloat(keypointInfo.col) + 0.5) / CGFloat(OpenPosePoseEstimator.Output.ConfidenceMap.width)
            let y = (CGFloat(keypointInfo.row) + 0.5) / CGFloat(OpenPosePoseEstimator.Output.ConfidenceMap.height)
            let score = Float(keypointInfo.val)
            
            return (point: CGPoint(x: x, y: y), score: score)
        }
        
        return keypointInfos.map { keypointInfo in Keypoint(position: keypointInfo.point, score: keypointInfo.score) }
    }
    
    func makeLines(with keypoints: [Keypoint]) -> [Line] {
        var keypointWithBodyPart: [OpenPosePoseEstimator.Output.BodyPart: Keypoint] = [:]
        OpenPosePoseEstimator.Output.BodyPart.allCases.enumerated().forEach { (index, bodyPart) in
            keypointWithBodyPart[bodyPart] = keypoints[index]
        }
        return OpenPosePoseEstimator.Output.BodyPart.lines.compactMap { line in
            guard let fromKeypoint = keypointWithBodyPart[line.from],
                let toKeypoint = keypointWithBodyPart[line.to] else { return nil }
            return (from: fromKeypoint, to: toKeypoint)
        }
    }
}

extension TFLiteFlatArray where Element == Float32 {
    // part confidence maps
    subscript(heatmap heatmap: Int...) -> Element {
        get { return self.element(at: heatmap) }
    }
    
    // part affinity fields
    subscript(paf paf: Int...) -> Element {
        get {
            var indexes = paf
            indexes[indexes.count-1] = indexes[indexes.count-1] + OpenPosePoseEstimator.Output.ConfidenceMap.count
            return self.element(at: indexes)
        }
    }
}
