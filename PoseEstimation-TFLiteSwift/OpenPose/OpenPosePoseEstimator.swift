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
    
    var modelOutput: [TFLiteFlatArray<Float32>]?
    
    func inference(_ input: PoseEstimationInput, with threshold: Float?, on partIndex: Int?) -> OpenPoseResult {
        
        // initialize
        modelOutput = nil
        
        // preprocss
        guard let inputData = imageInterpreter.preprocess(with: input)
            else { return .failure(.failToCreateInputData) }
        
        // inference
        modelOutput = imageInterpreter.inference(with: inputData)
        guard let outputs = modelOutput
            else { return .failure(.failToInference) }
        
        // postprocess
        let result = OpenPoseResult.success(postprocess(outputs, with: threshold, on: partIndex))
        
        return result
    }
    
    private func postprocess(_ outputs: [TFLiteFlatArray<Float32>], with threshold: Float?=nil, on partIndex: Int?=nil) -> PoseEstimationOutput {
        // if you want to postprocess with only single person, use .singlePerson on humanType
        // in .multiPerson, if the bodyPart is nil, parse all part
        return PoseEstimationOutput(outputs: outputs, humanType: .multiPerson(threshold: threshold, bodyPart: partIndex))
    }
    
    func postprocessOnLastOutput(with threshold: Float?=nil, on partIndex: Int?=nil) -> PoseEstimationOutput? {
        guard let outputs = modelOutput else { return nil }
        return postprocess(outputs, with: threshold, on: partIndex)
    }
    
    var partNames: [String] {
        return Output.BodyPart.allCases.map { $0.rawValue }
    }
    
    var pairNames: [String]? {
        return Output.BodyPart.lines.map {
            return "\($0.from.shortName())-\($0.to.shortName())"
        }
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
            case NOSE = "Nose"                  // 0
            case NECK = "Neck"                  // 1
            case RIGHT_SHOULDER = "RShoulder"   // 2
            case RIGHT_ELBOW = "RElbow"         // 3
            case RIGHT_WRIST = "RWrist"         // 4
            case LEFT_SHOULDER = "LShoulder"    // 5
            case LEFT_ELBOW = "LElbow"          // 6
            case LEFT_WRIST = "LWrist"          // 7
            case RIGHT_HIP = "RHip"             // 8
            case RIGHT_KNEE = "RKnee"           // 9
            case RIGHT_ANKLE = "RAnkle"         // 10
            case LEFT_HIP = "LHip"              // 11
            case LEFT_KNEE = "LKnee"            // 12
            case LEFT_ANKLE = "LAnkle"          // 13
            case RIGHT_EYE = "REye"             // 14
            case LEFT_EYE = "LEye"              // 15
            case RIGHT_EAR = "REar"             // 16
            case LEFT_EAR = "LEar"              // 17
            case BACKGROUND = "Background"      // 18
            
            init(offsetValue: Int) {
                switch offsetValue {
                case 0: self = .NOSE
                case 1: self = .NECK
                case 2: self = .RIGHT_SHOULDER
                case 3: self = .RIGHT_ELBOW
                case 4: self = .RIGHT_WRIST
                case 5: self = .LEFT_SHOULDER
                case 6: self = .LEFT_ELBOW
                case 7: self = .LEFT_WRIST
                case 8: self = .RIGHT_HIP
                case 9: self = .RIGHT_KNEE
                case 10: self = .RIGHT_ANKLE
                case 11: self = .LEFT_HIP
                case 12: self = .LEFT_KNEE
                case 13: self = .LEFT_ANKLE
                case 14: self = .RIGHT_EYE
                case 15: self = .LEFT_EYE
                case 16: self = .RIGHT_EAR
                case 17: self = .LEFT_EAR
                case 18: self = .BACKGROUND
                default: self = .BACKGROUND
                }
            }
            
            func offsetValue() -> Int {
                switch self {
                case .NOSE: return 0
                case .NECK: return 1
                case .RIGHT_SHOULDER: return 2
                case .RIGHT_ELBOW: return 3
                case .RIGHT_WRIST: return 4
                case .LEFT_SHOULDER: return 5
                case .LEFT_ELBOW: return 6
                case .LEFT_WRIST: return 7
                case .RIGHT_HIP: return 8
                case .RIGHT_KNEE: return 9
                case .RIGHT_ANKLE: return 10
                case .LEFT_HIP: return 11
                case .LEFT_KNEE: return 12
                case .LEFT_ANKLE: return 13
                case .RIGHT_EYE: return 14
                case .LEFT_EYE: return 15
                case .RIGHT_EAR: return 16
                case .LEFT_EAR: return 17
                case .BACKGROUND: return 18
                }
            }
            
            func shortName() -> String {
                switch self {
                case .NOSE: return "No"
                case .NECK: return "Ne"
                case .RIGHT_SHOULDER: return "RSh"
                case .RIGHT_ELBOW: return "REl"
                case .RIGHT_WRIST: return "RWr"
                case .LEFT_SHOULDER: return "LSh"
                case .LEFT_ELBOW: return "LEl"
                case .LEFT_WRIST: return "LWr"
                case .RIGHT_HIP: return "RHi"
                case .RIGHT_KNEE: return "RKn"
                case .RIGHT_ANKLE: return "RAn"
                case .LEFT_HIP: return "LHi"
                case .LEFT_KNEE: return "LKn"
                case .LEFT_ANKLE: return "LAn"
                case .RIGHT_EYE: return "REy"
                case .LEFT_EYE: return "LEy"
                case .RIGHT_EAR: return "REa"
                case .LEFT_EAR: return "LEa"
                case .BACKGROUND: return "BG"
                }
            }
            
            static let lines = [
                (from: BodyPart.NECK, to: BodyPart.RIGHT_HIP),              // 0
                (from: BodyPart.RIGHT_HIP, to: BodyPart.RIGHT_KNEE),        // 1
                (from: BodyPart.RIGHT_KNEE, to: BodyPart.RIGHT_ANKLE),      // 2

                (from: BodyPart.NECK, to: BodyPart.LEFT_HIP),               // 3
                (from: BodyPart.LEFT_HIP, to: BodyPart.LEFT_KNEE),          // 4
                (from: BodyPart.LEFT_KNEE, to: BodyPart.LEFT_ANKLE),        // 5

                (from: BodyPart.NECK, to: BodyPart.RIGHT_SHOULDER),         // 6
                (from: BodyPart.RIGHT_SHOULDER, to: BodyPart.RIGHT_ELBOW),  // 7
                (from: BodyPart.RIGHT_ELBOW, to: BodyPart.RIGHT_WRIST),     // 8
                (from: BodyPart.RIGHT_SHOULDER, to: BodyPart.RIGHT_EAR),    // 9

                (from: BodyPart.NECK, to: BodyPart.LEFT_SHOULDER),          // 10
                (from: BodyPart.LEFT_SHOULDER, to: BodyPart.LEFT_ELBOW),    // 11
                (from: BodyPart.LEFT_ELBOW, to: BodyPart.LEFT_WRIST),       // 12
                (from: BodyPart.LEFT_SHOULDER, to: BodyPart.LEFT_EAR),      // 13
                
                (from: BodyPart.NECK, to: BodyPart.NOSE),                   // 14
                (from: BodyPart.NOSE, to: BodyPart.RIGHT_EYE),              // 15
                (from: BodyPart.NOSE, to: BodyPart.LEFT_EYE),               // 16
                (from: BodyPart.RIGHT_EYE, to: BodyPart.RIGHT_EAR),         // 17
                (from: BodyPart.LEFT_EYE, to: BodyPart.LEFT_EAR),           // 18
            ]
        }
    }
}

private extension PoseEstimationOutput {
    enum HumanType {
        case singlePerson
        case multiPerson(threshold: Float?, bodyPart: Int?)
    }
    
    init(outputs: [TFLiteFlatArray<Float32>], humanType: HumanType = .singlePerson) {
        self.outputs = outputs
        
        switch humanType {
        case .singlePerson:
            let keypoints = convertToKeypoints(from: outputs)
            let lines = makeLines(with: keypoints)
            humans = [Human(keypoints: keypoints, lines: lines)]
        case .multiPerson(threshold: let threshold, let bodyPart):
            humans = parseMultiHuman(from: outputs, on: bodyPart, with: threshold)
        }
    }
    
    func convertToKeypoints(from outputs: [TFLiteFlatArray<Float32>]) -> [Keypoint] {
        let output = outputs[0] // openpose_ildoonet.tflite only use the first output
        
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
    
    func makeLines(with keypoints: [Keypoint]) -> [Human.Line] {
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
    
    func parseMultiHuman(from outputs: [TFLiteFlatArray<Float32>], on partIndex: Int?, with threshold: Float?) -> [Human] {
        // openpose_ildoonet.tflite only use the first output
        let output = outputs[0]
        
        if let partIndex = partIndex {
            return parseSinglePartOnMultiHuman(from: output, on: partIndex, with: threshold)
        } else {
            return parseAllPartOnMultiHuman(from: output, with: threshold)
        }
    }
    
    func parseSinglePartOnMultiHuman(from output: TFLiteFlatArray<Float32>, on partIndex: Int, with threshold: Float?) -> [Human] {
        // process NMS
        let keypointIndexes = output.keypoints(partIndex: partIndex, filterSize: 3, threshold: threshold)
        
        // convert col,row to Keypoint
        let kps: [Keypoint] = keypointIndexes.map { keypointInfo in
            return Keypoint(column: keypointInfo.col,
                            row: keypointInfo.row,
                            width: OpenPosePoseEstimator.Output.ConfidenceMap.width,
                            height: OpenPosePoseEstimator.Output.ConfidenceMap.height,
                            value: keypointInfo.val)
        }
        
        // Make [Human]
        return kps.map { keypoint in
            let keypoints: [Keypoint?] = OpenPosePoseEstimator.Output.BodyPart.allCases.enumerated().map { offset, _ in
                return (offset == partIndex) ? keypoint : nil
            }
            return Human(keypoints: keypoints, lines: [])
        }
    }
    
    func parseAllPartOnMultiHuman(from output: TFLiteFlatArray<Float32>, with threshold: Float?) -> [Human] {
        let parts = OpenPosePoseEstimator.Output.BodyPart.allCases
        var verticesForEachPart: [[KeypointElement]?] = parts.map { _ in nil }
        let pairs = OpenPosePoseEstimator.Output.BodyPart.lines
        var edgesForEachPair: [[(from: KeypointElement, to: KeypointElement, cost: Float32)]] = pairs.map { _ in [] }
        let (colSize, rowSize) = (OpenPosePoseEstimator.Output.ConfidenceMap.width,
                                  OpenPosePoseEstimator.Output.ConfidenceMap.height)
        
        for (pairIndex, pair) in pairs.enumerated() {
            // guard pairIndex == 0 else { continue }
            
            let startingPartIndex = pair.from.offsetValue()
            let endingPartIndex = pair.to.offsetValue()
            
            let thresholdRatio: Float = 1.0 // 0.5 + (1.0 - (Float(pairIndex+1)/Float(pairCount))) * 0.5 // 1.0~>0.5
            
            // 1. Non Maximum Suppression, 2. Create Bipartite Graph
            let startingPartVertices: [KeypointElement]
            let endingPartVertices: [KeypointElement]
            // get starting keypoints
            if let sv = verticesForEachPart[startingPartIndex] {
                startingPartVertices = sv
            } else {
                startingPartVertices = output.keypoints(partIndex: startingPartIndex,
                                                        filterSize: 5,
                                                        threshold: threshold*thresholdRatio).map {
                    KeypointElement(element: $0)
                }
                verticesForEachPart[startingPartIndex] = startingPartVertices
            }
            // get ending keypoints
            if let ev = verticesForEachPart[endingPartIndex] {
                endingPartVertices = ev
            } else {
                endingPartVertices = output.keypoints(partIndex: endingPartIndex,
                                                      filterSize: 5,
                                                      threshold: threshold*thresholdRatio).map {
                    KeypointElement(element: $0)
                }
                verticesForEachPart[endingPartIndex] = endingPartVertices
            }
            
            for startingPartVertex in startingPartVertices {
                for endingPartVertex in endingPartVertices {
                    // 3. Line Integral
                    // vx, vy
                    let (sCol, eCol) = (startingPartVertex.col, endingPartVertex.col)
                    let (sRow, eRow) = (startingPartVertex.row, endingPartVertex.row)
                    let (xDiff, yDiff) = (Float(eCol-sCol), Float(eRow-sRow))
                    guard xDiff != 0 || yDiff != 0 else { continue }
                    let vLength = sqrt(pow(xDiff, 2) + pow(yDiff, 2))
                    let (vx, vy) = (xDiff/vLength, yDiff/vLength)
                    // sampling
                    let numberOfSamples = 10
                    let dx = xDiff / Float(numberOfSamples)
                    let dy = yDiff / Float(numberOfSamples)
                    let sampledLocaitons: [(col: Int, row: Int)] = (0..<numberOfSamples).map { index in
                        let col = Int(roundf(Float32(startingPartVertex.col) + (dx*(Float32(index)+0.5))))
                        let row = Int(roundf(Float32(startingPartVertex.row) + (dy*(Float32(index)+0.5))))
                        return (col: min(max(col, 0), colSize-1), row: min(max(row, 0), rowSize-1))
                    }
                    // integral
                    let cost: Float32 = sampledLocaitons.reduce(0.0) {
                        let (pafX, pafY) = output[paf: 0, $1.row, $1.col, pairIndex]
                        let dotProductedValue = (pafX * vx + pafY * vy)
                        return $0 + dotProductedValue
                    }
                    edgesForEachPair[pairIndex].append((from: startingPartVertex, to: endingPartVertex, cost: cost))
                }
            }
            
            // 4. Assignment
            var edges = edgesForEachPair[pairIndex]
            edges = edges.filter { $0.cost > 0.2 }
            edges = edges.sorted { $0.cost > $1.cost }
            
            // remove used pairs
            var index = 1
            while index < edges.count {
                let edge = edges[index]
                let duplicated = edges[0..<index].filter {
                    ($0.from.col == edge.from.col && $0.from.row == edge.from.row) ||
                    ($0.to.col == edge.to.col && $0.to.row == edge.to.row)
                }
                if !duplicated.isEmpty {
                    edges.remove(at: index)
                } else {
                    index += 1
                }
            }
            
            edgesForEachPair[pairIndex] = edges
        }
        
        // 5. Merging
        var tmpHumans: [[KeypointElement?]] = []
        for (pair, edges) in zip(pairs, edgesForEachPair) {
            let startingPartIndex = pair.from.offsetValue()
            let endingPartIndex = pair.to.offsetValue()
            for edge in edges {
                if let hummanIndex = tmpHumans.enumerated()
                    .filter({ $1[startingPartIndex]?.col == edge.from.col &&
                    $1[startingPartIndex]?.row == edge.from.row }).first?.offset {
                    // just connect
                    if tmpHumans[hummanIndex][endingPartIndex] == nil {
                        tmpHumans[hummanIndex][endingPartIndex] = edge.to
                    }
                } else {
                    // create new human
                    var tmpHuman: [KeypointElement?] = parts.map { _ in nil }
                    tmpHuman[startingPartIndex] = edge.from
                    tmpHuman[endingPartIndex] = edge.to
                    tmpHumans.append(tmpHuman)
                }
            }
        }
        
        let humans: [Human] = tmpHumans.map { tmpHuman in
            let keypoints: [Keypoint?] = tmpHuman.enumerated().map { (offset, locationInfo) in
                guard let locationInfo = locationInfo else { return nil }
                return Keypoint(column: locationInfo.col,
                                row: locationInfo.row,
                                width: colSize,
                                height: rowSize,
                                value: locationInfo.val)
            }
            let lines: [(from: Keypoint, to: Keypoint)] = pairs.compactMap { pair in
                guard let startingKeypoint = keypoints[pair.from.offsetValue()],
                    let endingKeypoint = keypoints[pair.to.offsetValue()] else { return nil }
                return (from: startingKeypoint, to: endingKeypoint)
            }
            return Human(keypoints: keypoints, lines: lines)
        }
        return humans
    }
}

extension TFLiteFlatArray where Element == Float32 {
    // part confidence maps
    subscript(heatmap heatmap: Int...) -> Element {
        get { return self.element(at: heatmap) }
    }
    
    // part affinity fields
    subscript(paf pafIndexes: Int...) -> (x: Element, y: Element) {
        get {
            let pafYOffset = (pafIndexes[3]*2) + 1 + OpenPosePoseEstimator.Output.BodyPart.allCases.count
            let pafXOffset = (pafIndexes[3]*2) + 0 + OpenPosePoseEstimator.Output.BodyPart.allCases.count
            let x = self.element(at: [pafIndexes[0], pafIndexes[1], pafIndexes[2], pafXOffset])
            let y = self.element(at: [pafIndexes[0], pafIndexes[1], pafIndexes[2], pafYOffset])
            return (x: x, y: y)
        }
    }
}

// NMS
private extension TFLiteFlatArray where Element == Float32 {
    func keypoints(partIndex: Int, filterSize: Int, threshold: Float?) -> [(col: Int, row: Int, val: Element)] {
        let hWidth = OpenPosePoseEstimator.Output.ConfidenceMap.width
        let hHeight = OpenPosePoseEstimator.Output.ConfidenceMap.height
        let results = NonMaximumnonSuppression.process(self, partIndex: partIndex, width: hWidth, height: hHeight)
        if let threshold = threshold {
            return results.filter { $0.val > threshold }
        } else {
            return results
        }
    }
}

private extension Keypoint {
    init(column: Int, row: Int, width: Int, height: Int, value: Float32) {
        let x = (CGFloat(column) + 0.5) / CGFloat(width)
        let y = (CGFloat(row) + 0.5) / CGFloat(height)
        position = CGPoint(x: x, y: y)
        score = Float(value)
    }
}

extension Float32 {
    func string(_ format: String = "%.2f") -> String {
        return String(format: format, self)
    }
}

extension Optional where Wrapped == Float {
    static func *(lhs: Wrapped?, rhs: Float) -> Self {
        guard let lhs = lhs else { return nil }
        return some(lhs * rhs)
    }
}
