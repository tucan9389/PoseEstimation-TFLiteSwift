//
//  HumanKeypoints.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2021/07/11.
//  Copyright © 2021 Doyoung Gwak. All rights reserved.
//

import CoreGraphics
// import MLKitPoseDetectionAccurate
// import MLKitVision

class Keypoint {
    
    let x: Float
    let y: Float
    let z: Float?
    let score: Float
    var is3D: Bool { return z != nil }
    
    init(x: Float, y: Float, z: Float?, s: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.score = s
    }
    
    var location2D: CGPoint {
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
    
    var yFlip: Keypoint {
        return Keypoint(x: x, y: 1-y, z: z, s: score)
    }
}

enum HumanKeypointName: Int, CaseIterable {
    case nose           = 0
    case neck           = 1
    
    case rightShoulder  = 2
    case rightElbow     = 3
    case rightWrist     = 4
    case leftShoulder   = 5
    case leftElbow      = 6
    case leftWrist      = 7
    
    case rightHip       = 8
    case rightKnee      = 9
    case rightAnkle     = 10
    case leftHip        = 11
    case leftKnee       = 12
    case leftAnkle      = 13
}

class HumanKeypoints {
    
    let keypoints: [Keypoint?]
    var is3D: Bool { return keypoints.first??.is3D == true }
    
    typealias Line = (from: Keypoint?, to: Keypoint?)
    static var lineInfos: [(from: HumanKeypointName, to: HumanKeypointName)] = [
        (.nose, .neck),
        
        (.neck, .rightShoulder),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.rightShoulder, .rightHip),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),
        
        (.rightHip, .leftHip),
        
        (.neck, .leftShoulder),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.leftShoulder, .leftHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
    ]
    var lines: [Line] {
        return HumanKeypoints.lineInfos.map { (keypoints[$0.from.rawValue], keypoints[$0.to.rawValue]) }
    }
    
    init(keypoints: [Keypoint?]) {
        self.keypoints = keypoints
    }
    
    init(human3d: PoseEstimationOutput.Human3D, adjustMode: Bool = false) {
        let allParts = LiteBaseline3DPoseEstimator.Output.BodyPart.allCases
        let partToIndex: [LiteBaseline3DPoseEstimator.Output.BodyPart: Int] = Dictionary(uniqueKeysWithValues: allParts.enumerated().map { ($0.element, $0.offset) })
        let jointParts: [LiteBaseline3DPoseEstimator.Output.BodyPart] = [
            .HEAD,
            .THORAX,
            
            .RIGHT_SHOULDER,
            .RIGHT_ELBOW,
            .RIGHT_WRIST,
            .LEFT_SHOULDER,
            .LEFT_ELBOW,
            .LEFT_WRIST,
            
            .RIGHT_HIP,
            .RIGHT_KNEE,
            .RIGHT_ANKLE,
            .LEFT_HIP,
            .LEFT_KNEE,
            .LEFT_ANKLE,
        ]
        
        let kps = adjustMode ? human3d.keypoints : human3d.adjustKeypoints()
        self.keypoints = jointParts.map {
            guard let kpIndex = partToIndex[$0], let point = kps[kpIndex] else { return nil }
            return Keypoint(x: Float(point.position.x), y: Float(point.position.y), z: Float(point.position.z), s: point.score)
        }
    }
    
  /*
    init(mlkitPose: Pose, imageSize: CGSize) {
        let jointParts: [PoseLandmarkType] = [
            .nose,
            .nose,  // need to average value of rightShoulder and leftShoulde
            
            .rightShoulder,
            .rightElbow,
            .rightWrist,
            .leftShoulder,
            .leftElbow,
            .leftWrist,
            
            .rightHip,
            .rightKnee,
            .rightAnkle,
            .leftHip,
            .leftKnee,
            .leftAnkle,
        ]
        
        let maxZ: CGFloat = (imageSize.height + imageSize.width) * 0.8 // CGFloat.leastNormalMagnitude
        let minZ: CGFloat = -maxZ // CGFloat.greatestFiniteMagnitude
//        jointParts.forEach {
//            let position = mlkitPose.landmark(ofType: $0).position
//            maxZ = max(position.z, maxZ)
//            minZ = min(position.z, minZ)
//        }
        let zDistance = abs(maxZ - minZ)
//        minZ -= zDistance*2
//        maxZ += zDistance*2
//        zDistance = abs(maxZ - minZ)
//
//        print(maxZ, minZ, imageSize)
        
        self.keypoints = jointParts.enumerated().map {
            if $0 == 1 {
                let landmark1 = mlkitPose.landmark(ofType: .rightShoulder)
                let landmark2 = mlkitPose.landmark(ofType: .leftShoulder)
                let absoluteZ = (landmark1.position.z + landmark2.position.z) / 2
                let x = (landmark1.position.x + landmark2.position.x) / 2
                let y = (landmark1.position.y + landmark2.position.y) / 2
                let z = Float((absoluteZ - minZ) / zDistance)
                let s = (landmark1.inFrameLikelihood + landmark2.inFrameLikelihood) / 2
                return Keypoint(x: Float(x / imageSize.width), y: Float(1 - (y / imageSize.height)), z: z, s: s)
            } else {
                let position = mlkitPose.landmark(ofType: $1).position
                let z = Float((position.z - minZ) / zDistance)
                return Keypoint(x: Float(position.x / imageSize.width), y: Float(1 - (position.y / imageSize.height)), z: z, s: mlkitPose.landmark(ofType: $1).inFrameLikelihood)
            }
        }
    }
   */
    
    init(vision2DPoseKeypoints: HumanKeypoints, mlkit3DPoseKeypoints: HumanKeypoints) {
        self.keypoints = zip(vision2DPoseKeypoints.keypoints, mlkit3DPoseKeypoints.keypoints).enumerated().map {
            guard let kp2D = $1.0, let kp3D = $1.1 else { return nil }
            let z: Float?
            if $0 == HumanKeypointName.neck.rawValue {
                z = ((mlkit3DPoseKeypoints.keypoints[HumanKeypointName.rightShoulder.rawValue]?.z ?? 0) + (mlkit3DPoseKeypoints.keypoints[HumanKeypointName.leftShoulder.rawValue]?.z ?? 0)) / 2
            } else {
                z = kp3D.z
            }
            if kp2D.score < 0.4 {
                return Keypoint(x: kp3D.x, y: kp3D.y, z: z, s: kp3D.score)
            } else {
                return Keypoint(x: kp2D.x, y: kp2D.y, z: z, s: kp3D.score)
            }
            
        }
    }
    
//    var predictedPoints: [PredictedPoint?] {
//        return keypoints.map {
//            guard let keypoint = $0 else { return nil }
//            return PredictedPoint(maxPoint: CGPoint(x: CGFloat(keypoint.x), y: CGFloat(keypoint.y)), maxConfidence: Double(keypoint.score))
//        }
//    }
    
    subscript(keypointName: HumanKeypointName) -> Keypoint? {
        let kpIndex = keypointName.rawValue
        guard (0..<keypoints.count).contains(kpIndex) else { return nil }
        return keypoints[kpIndex]
    }
    
    init(kpsArray: [HumanKeypoints]) {
        guard let firstKeypoints = kpsArray.first else { self.keypoints = []; return }
        self.keypoints = (0..<firstKeypoints.keypoints.count).map { idx in
            guard let x: Float = kpsArray[(kpsArray.count-1)/2].keypoints[idx]?.x,
                  let y: Float = kpsArray[(kpsArray.count-1)/2].keypoints[idx]?.y else { return nil }
            let z: Float = kpsArray.compactMap { $0.keypoints[idx]?.z }.reduce(0) { $0 + $1 } / Float((kpsArray.compactMap { $0.keypoints[idx]?.z }).count)
            let s: Float = kpsArray.compactMap { $0.keypoints[idx]?.score }.reduce(0) { $0 + $1 } / Float((kpsArray.compactMap { $0.keypoints[idx]?.score }).count)
            return Keypoint(x: x, y: y, z: z, s: s)
        }
    }
}

extension CGRect {
    func iou(with rect: CGRect) -> CGFloat {
        let r1 = self
        let r2 = rect
        let x1 = max(r1.origin.x, r2.origin.x)
        let x2 = min(r1.origin.x + r1.width, r2.origin.x + r2.width)
        guard x1 < x2 else { return 0 }
        let y1 = max(r1.origin.y, r2.origin.y)
        let y2 = min(r1.origin.y + r1.height, r2.origin.y + r2.height)
        guard y1 < y2 else { return 0 }
        let intersactionArea = (x2 - x1) * (y2 - y1)
        let unionArea = (r1.width * r1.height) + (r2.width * r2.height) - intersactionArea
        return intersactionArea / unionArea
    }
    
    var center: CGPoint {
        return CGPoint(x: origin.x + width/2, y: origin.y + height/2)
    }
    
    var squareRect: CGRect {
        let longLength = width > height ? width : height
        return CGRect(x: center.x - longLength / 2, y: center.y - longLength / 2, width: longLength, height: longLength)
    }
    
    static func * (_ lsh: CGRect, rsh: CGSize) -> CGRect {
        return CGRect(x: lsh.origin.x * rsh.width, y: lsh.origin.y * rsh.height, width: lsh.width * rsh.width, height: lsh.height * rsh.height)
    }
    
    var yFlip: CGRect {
        return CGRect(x: origin.x, y: 1 - origin.y - height, width: width, height: height)
    }
    
    func adjustAsInside(parentSize: CGSize) -> CGRect {
        let x: CGFloat
        if origin.x < 0 {
            x = 0
        } else {
            x = origin.x
        }
        let w: CGFloat
        if x + width > parentSize.width {
            w = parentSize.width - x
        } else {
            w = width
        }
        let y: CGFloat
        if origin.y < 0 {
            y = 0
        } else {
            y = origin.y
        }
        let h: CGFloat
        if y + height > parentSize.height {
            h = parentSize.height - y
        } else {
            h = height
        }
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
