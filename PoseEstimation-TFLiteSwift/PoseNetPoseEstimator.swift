//
//  PoseNetPoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo

class PoseNetPoseEstimator: PoseEstimator {
    typealias PoseNetResult = Result<Keypoints, PoseEstimationError>
    
    lazy var imageInterpreter: TFLiteImageInterpreter = {
        let options = TFLiteImageInterpreter.Options(
            modelName: "posenet_mobilenet_v1_100_257x257_multi_kpt_stripped",
            inputWidth: Input.width,
            inputHeight: Input.height,
            isGrayScale: Input.isGrayScale,
            isNormalized: true
        )
        let imageInterpreter = TFLiteImageInterpreter(options: options)
        return imageInterpreter
    }()
    
    func inference(with pixelBuffer: CVPixelBuffer) -> PoseNetResult {
        // preprocss
        guard let inputData = imageInterpreter.preprocessMiddleSquareArea(with: pixelBuffer)
            else { return .failure(.failToCreateInputData) }
        // inference
        guard let outputs = imageInterpreter.inference(with: inputData)
            else { return .failure(.failToInference) }
        // postprocess
        let result = postprocess(with: outputs)
        
        return result
    }
    
    private func postprocess(with outputs: [TFLiteFlatArray<Float32>]) -> PoseNetResult {
        return .success(Keypoints(outputs: outputs))
    }
}

private extension PoseNetPoseEstimator {
    struct Input {
        static let width = 257
        static let height = 257
        static let isGrayScale = false
    }
    struct Output {
        struct Heatmap {
            static let width = 9
            static let height = 9
            static let count = 17
        }
        struct Offset {
            static let width = 9
            static let height = 9
            static let count = 34
        }
    }
}

private extension Keypoints {
    init(outputs: [TFLiteFlatArray<Float32>]) {
        let heatmaps = outputs[0]
        let offsets = outputs[1]
        
        // get (col, row)s from heatmaps
        let keypointIndexInfos: [(row: Int, col: Int, val: Float32)] = (0..<PoseNetPoseEstimator.Output.Heatmap.count).map { heatmapIndex in
            var maxInfo = (row: 0, col: 0, val: heatmaps[0, 0, 0, heatmapIndex])
            for row in 0..<PoseNetPoseEstimator.Output.Heatmap.height {
                for col in 0..<PoseNetPoseEstimator.Output.Heatmap.width {
                    if heatmaps[0, row, col, heatmapIndex] > maxInfo.val {
                        maxInfo = (row: row, col: col, val: heatmaps[0, row, col, heatmapIndex])
                    }
                }
            }
            return maxInfo
        }
        
        // get points from (col, row)s and offsets
        let keypointInfos: [(point: CGPoint, score: CGFloat)] = keypointIndexInfos.enumerated().map { (index, keypointInfo) in
            // (0.0, 0.0)~(1.0, 1.0)
            let xNaive = (CGFloat(keypointInfo.col) + 0.5) / CGFloat(PoseNetPoseEstimator.Output.Heatmap.width)
            let yNaive = (CGFloat(keypointInfo.row) + 0.5) / CGFloat(PoseNetPoseEstimator.Output.Heatmap.height)
            
            // (0.0, 0.0)~(Input.width, Input.height)
            let xOffset = offsets[0, keypointInfo.row, keypointInfo.col, index + PoseNetPoseEstimator.Output.Heatmap.count]
            let yOffset = offsets[0, keypointInfo.row, keypointInfo.col, index]
            
            // (0.0, 0.0)~(Input.width, Input.height)
            let xScaledInput = xNaive * CGFloat(PoseNetPoseEstimator.Input.width) + CGFloat(xOffset)
            let yScaledInput = yNaive * CGFloat(PoseNetPoseEstimator.Input.height) + CGFloat(yOffset)
            
            // (0.0, 0.0)~(1.0, 1.0)
            let x = xScaledInput / CGFloat(PoseNetPoseEstimator.Input.width)
            let y = yScaledInput / CGFloat(PoseNetPoseEstimator.Input.height)
            let score = CGFloat(keypointInfo.val)
            
            return (point: CGPoint(x: x, y: y), score: score)
        }
        
        keypoints = keypointInfos.map { keypointInfo in Keypoint(position: keypointInfo.point, score: keypointInfo.score) }
    }
}
