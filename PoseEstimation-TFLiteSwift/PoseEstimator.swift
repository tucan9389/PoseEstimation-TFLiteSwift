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
//  PoseEstimator.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import CoreVideo
import UIKit
import simd
import TFLiteSwift_Vision

struct PreprocessOptions {
    let cropArea: CropArea
    
    enum CropArea {
        case customAspectFill(rect: CGRect)
        case squareAspectFill
    }
}

struct PostprocessOptions {
    let partThreshold: Float?
    let bodyPart: Int?
    let humanType: HumanType
    
    enum HumanType {
        case singlePerson
        case multiPerson(pairThreshold: Float?, nmsFilterSize: Int, maxHumanNumber: Int?)
    }
}

enum PoseEstimationInput {
    case pixelBuffer(pixelBuffer: CVPixelBuffer, preprocessOptions: PreprocessOptions, postprocessOptions: PostprocessOptions)
    case uiImage(uiImage: UIImage, preprocessOptions: PreprocessOptions, postprocessOptions: PostprocessOptions)
    case cgImage(cgImage: CGImage, preprocessOptions: PreprocessOptions, postprocessOptions: PostprocessOptions)
    
    var pixelBuffer: CVPixelBuffer? {
        switch self {
        case .pixelBuffer(let pixelBuffer, _, _):
            return pixelBuffer
        case .uiImage(let uiImage, _, _):
            return uiImage.pixelBufferFromImage()
        case .cgImage(let cgImage, _, _):
            return cgImage.pixelBufferFromImage()
        }
    }
    
    var cropArea: PreprocessOptions.CropArea {
        switch self {
        case .pixelBuffer(_, let preprocessOptions, _):
            return preprocessOptions.cropArea
        case .uiImage(_, let preprocessOptions, _):
            return preprocessOptions.cropArea
        case .cgImage(_, let preprocessOptions, _):
            return preprocessOptions.cropArea
        }
    }
    
    var imageSize: CGSize {
        switch self {
        case .pixelBuffer(let pixelBuffer, _, _):
            return pixelBuffer.size
        case .uiImage(let uiImage, _, _):
            return uiImage.size
        case .cgImage(let cgImage, _, _):
            return CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        }
    }
    
    var targetSquare: CGRect {
        switch cropArea {
        case .customAspectFill(let rect):
            return rect
        case .squareAspectFill:
            let size = imageSize
            let minLength = min(size.width, size.height)
            return CGRect(x: (size.width - minLength) / 2,
                          y: (size.height - minLength) / 2,
                          width: minLength, height: minLength)
        }
    }
    
    var partThreshold: Float? {
        return postprocessOptions.partThreshold
    }
    
    var bodyPart: Int? {
        return postprocessOptions.bodyPart
    }
    
    var postprocessOptions: PostprocessOptions {
        switch self {
        case .pixelBuffer(_, _, let options):
            return options
        case .uiImage(_, _, let options):
            return options
        case .cgImage(_, _, let options):
            return options
        }
    }
    
    func croppedPixelBuffer(with inputModelSize: CGSize) -> CVPixelBuffer? {
        guard let pixelBuffer = pixelBuffer else { return nil }
        let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        assert(sourcePixelFormat == kCVPixelFormatType_32BGRA)
        
        // Resize `targetSquare` of input image to `modelSize`.
        return pixelBuffer.resize(from: targetSquare, to: inputModelSize)
    }
}

struct Keypoint2D {
    let position: CGPoint
    let score: Float
}

struct KeypointElement: Equatable {
    let col: Int
    let row: Int
    let val: Float32
    
    init(element: (col: Int, row: Int, val: Float32)) {
        col = element.col
        row = element.row
        val = element.val
    }
    
    static func == (lhs: KeypointElement, rhs: KeypointElement) -> Bool {
        return lhs.col == rhs.col && lhs.row == rhs.row
    }
}

struct Keypoint3D {
    
    struct Point3D {
        let x: CGFloat
        let y: CGFloat
        let z: CGFloat
        
        var simdVector: simd_float3 {
            return simd_float3(x: Float(x), y: Float(y), z: Float(z))
        }
    }
    
    let position: Point3D
    let score: Float
    
    init(x: CGFloat, y: CGFloat, z: CGFloat, s: Float = 1.0) {
        position = Point3D(x: x, y: y, z: z)
        score = s
    }
    
    static func - (lhs: Keypoint3D, rhs: Keypoint3D) -> Keypoint3D {
        return Keypoint3D(
            x: lhs.position.x - rhs.position.x,
            y: lhs.position.y - rhs.position.y,
            z: lhs.position.z - rhs.position.z
        )
    }
    static func + (lhs: Keypoint3D, rhs: Keypoint3D) -> Keypoint3D {
        return Keypoint3D(
            x: lhs.position.x + rhs.position.x,
            y: lhs.position.y + rhs.position.y,
            z: lhs.position.z + rhs.position.z
        )
    }
    static func * (lhs: Keypoint3D, rhs: Keypoint3D) -> Keypoint3D {
        return Keypoint3D(
            x: lhs.position.x * rhs.position.x,
            y: lhs.position.y * rhs.position.y,
            z: lhs.position.z * rhs.position.z
        )
    }
    static func / (lhs: Keypoint3D, rhs: Keypoint3D) -> Keypoint3D {
        return Keypoint3D(
            x: lhs.position.x / rhs.position.x,
            y: lhs.position.y / rhs.position.y,
            z: lhs.position.z / rhs.position.z
        )
    }
    var distance: CGFloat {
        return pow(position.x*position.x + position.y*position.y + position.z*position.z, 0.5)
    }
    
    func product(rhs: Keypoint3D) -> CGFloat {
        let v = self * rhs
        return v.position.x + v.position.y + v.position.z
    }
}

struct PoseEstimationOutput {
    
    struct Human2D {
        typealias Line2D = (from: Keypoint2D, to: Keypoint2D)
        var keypoints: [Keypoint2D?] = []
        var lines: [Line2D] = []
    }
    
    struct Human3D {
        typealias Line3D = (from: Keypoint3D, to: Keypoint3D)
        var keypoints: [Keypoint3D?] = []
        var lines: [Line3D] = []
        var baselineKeypointIndexes: (Int, Int)? = nil
    }
    
    enum Human {
        case human2d(human: Human2D)
        case human3d(human: Human3D)
        
        var human2d: Human2D? {
            if case .human2d(let human) = self {
                return human
            } else { return nil }
        }
        var human3d: Human3D? {
            if case .human3d(let human) = self {
                return human
            } else { return nil }
        }
    }
    
    var outputs: [TFLiteFlatArray]
    var humans: [Human] = []
    var humans2d: [Human2D?] { return humans.map { $0.human2d } }
    var humans3d: [Human3D?] { return humans.map { $0.human3d } }
}

enum PoseEstimationError: Error {
    case failToCreateInputData
    case failToInference
    case failToPostprocess
}

protocol PoseEstimatorDelegate {
    func didEndInference(_ estimator: PoseEstimator, preprocessingTime: Double, inferenceTime: Double, postprocessingTime: Double)
}

protocol PoseEstimator {
    func inference(_ uiImage: UIImage, options: PostprocessOptions?) -> Result<PoseEstimationOutput, PoseEstimationError>
    func inference(_ pixelBuffer: CVPixelBuffer, options: PostprocessOptions?) -> Result<PoseEstimationOutput, PoseEstimationError>
    func postprocessOnLastOutput(options: PostprocessOptions) -> PoseEstimationOutput?
    var partNames: [String] { get }
    var pairNames: [String]? { get }
    var delegate: PoseEstimatorDelegate? { set get }
}

extension simd_float3 {
    var keypoint: Keypoint3D {
        return Keypoint3D(x: CGFloat(x), y: CGFloat(y), z: CGFloat(z))
    }
}
