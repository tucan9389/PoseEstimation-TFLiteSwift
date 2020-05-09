//
//  PEFMPoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/22.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo

class PEFMHourglassPoseEstimator: PoseEstimator {
    typealias PEFMHourglassResult = Result<PoseEstimationOutput, PoseEstimationError>
    
    lazy var imageInterpreter: TFLiteImageInterpreter = {
        let options = TFLiteImageInterpreter.Options(
            modelName: "pefm_hourglass_v2", // pefm_hourglass_v1
            inputWidth: Input.width,
            inputHeight: Input.height,
            isGrayScale: Input.isGrayScale,
            isNormalized: Input.isNormalized
        )
        let imageInterpreter = TFLiteImageInterpreter(options: options)
        return imageInterpreter
    }()
    
    var modelOutput: [TFLiteFlatArray<Float32>]?
    
    func inference(_ input: PoseEstimationInput) -> PEFMHourglassResult {
        
        // initialize
        modelOutput = nil
        
        // preprocss
        guard let inputData = imageInterpreter.preprocess(with: input)
            else { return .failure(.failToCreateInputData) }
        
        // inference
        guard let outputs = imageInterpreter.inference(with: inputData)
            else { return .failure(.failToInference) }
        
        // postprocess
        let result = PEFMHourglassResult.success(postprocess(with: outputs))
        
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

private extension PEFMHourglassPoseEstimator {
    struct Input {
        static let width = 192
        static let height = 192
        static let isGrayScale = false
        static let isNormalized = false
    }
    struct Output {
        struct Heatmap {
            static let width = 48
            static let height = 48
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
    init(outputs: [TFLiteFlatArray<Float32>]) {
        self.outputs = outputs
        
        let keypoints = convertToKeypoints(from: outputs)
        let lines = makeLines(with: keypoints)
        
        humans = [Human(keypoints: keypoints, lines: lines)]
    }
    
    func convertToKeypoints(from outputs: [TFLiteFlatArray<Float32>]) -> [Keypoint] {
        let heatmaps = outputs[0]
        
        // get (col, row)s from heatmaps
        let keypointIndexInfos: [(row: Int, col: Int, val: Float32)] = (0..<PEFMHourglassPoseEstimator.Output.Heatmap.count).map { heatmapIndex in
            var maxInfo = (row: 0, col: 0, val: heatmaps[0, 0, 0, heatmapIndex])
            for row in 0..<PEFMHourglassPoseEstimator.Output.Heatmap.height {
                for col in 0..<PEFMHourglassPoseEstimator.Output.Heatmap.width {
                    if heatmaps[0, row, col, heatmapIndex] > maxInfo.val {
                        maxInfo = (row: row, col: col, val: heatmaps[0, row, col, heatmapIndex])
                    }
                }
            }
            return maxInfo
        }
        
        // get points from (col, row)s and offsets
        let keypointInfos: [(point: CGPoint, score: Float)] = keypointIndexInfos.enumerated().map { (index, keypointInfo) in
            // (0.0, 0.0)~(1.0, 1.0)
            let x = (CGFloat(keypointInfo.col) + 0.5) / CGFloat(PEFMHourglassPoseEstimator.Output.Heatmap.width)
            let y = (CGFloat(keypointInfo.row) + 0.5) / CGFloat(PEFMHourglassPoseEstimator.Output.Heatmap.height)
            let score = Float(keypointInfo.val)
            
            return (point: CGPoint(x: x, y: y), score: score)
        }
        
        return keypointInfos.map { keypointInfo in Keypoint(position: keypointInfo.point, score: keypointInfo.score) }
    }
    
    func makeLines(with keypoints: [Keypoint]) -> [Human.Line] {
        var keypointWithBodyPart: [PEFMHourglassPoseEstimator.Output.BodyPart: Keypoint] = [:]
        PEFMHourglassPoseEstimator.Output.BodyPart.allCases.enumerated().forEach { (index, bodyPart) in
            keypointWithBodyPart[bodyPart] = keypoints[index]
        }
        return PEFMHourglassPoseEstimator.Output.BodyPart.lines.compactMap { line in
            guard let fromKeypoint = keypointWithBodyPart[line.from],
                let toKeypoint = keypointWithBodyPart[line.to] else { return nil }
            return (from: fromKeypoint, to: toKeypoint)
        }
    }
}
