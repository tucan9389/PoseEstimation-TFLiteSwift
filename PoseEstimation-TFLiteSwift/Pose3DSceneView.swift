//
//  Pose3DSceneView.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2021/03/13.
//  Copyright © 2021 Doyoung Gwak. All rights reserved.
//

import SceneKit
import QuartzCore

class Pose3DSceneView: SCNView {
    
    let studioSize: Float = 10.0
    let studioDepth: Float = 0.5
    let lineRadius: Float = 0.05
    let planeIndices: [HumanKeypointName] = [
        .rightShoulder, .neck, .leftShoulder, .leftHip, .rightHip
    ]
    
    var isAdjustMode = false
    var humanKeypoints: HumanKeypoints? {
        didSet {
            lines = humanKeypoints?.lines ?? []
            keypoints = humanKeypoints?.keypoints ?? []
        }
    }
    var lines: [HumanKeypoints.Line] = [] { didSet { updateLines(lines: lines) } }
    var keypoints: [Keypoint?] = [] {
        didSet {
            updateKeypoints(points: keypoints)
            updatePlane(points: planeIndices.filter { $0.rawValue < keypoints.count }.map { keypoints[$0.rawValue] }.compactMap { $0 })
        }
    }
    
    private var dotNodes: [SCNNode] = []
    private var lineNodes: [SCNNode] = []
    private var planeNodes: [SCNNode] = []
    
    func setupScene() {
        let newScene = SCNScene()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        newScene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 16)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 13, z: 9)
        newScene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        newScene.rootNode.addChildNode(ambientLightNode)
        
        // set the scene to the view
        scene = newScene
        
        // allows the user to manipulate the camera
        allowsCameraControl = true
        
        // show statistics such as fps and timing information
        showsStatistics = true
        
        // configure the view
        backgroundColor = UIColor.lightGray
        
        autoenablesDefaultLighting = true
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: self)
        let hitResults = hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    func setupBackgroundNodes() {
        guard let scene = scene else { return }
        
        let extendedStudioSize = studioSize * 1.2
        
        let boxNode = SCNNode(geometry: SCNBox(width: CGFloat(extendedStudioSize), height: CGFloat(extendedStudioSize), length: CGFloat(studioDepth), chamferRadius: 0.0))
        boxNode.position = SCNVector3(x: 0.0, y: 0.0, z: -extendedStudioSize/2.0)
        scene.rootNode.addChildNode(boxNode)
        
        let floorNode = SCNNode(geometry: SCNBox(width: CGFloat(extendedStudioSize), height: CGFloat(studioDepth), length: CGFloat(extendedStudioSize), chamferRadius: 0.0))
        floorNode.position = SCNVector3(x: 0.0, y: -extendedStudioSize/2.0, z: 0.0)
        scene.rootNode.addChildNode(floorNode)
    }
    
    func makeLineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, scene: SCNScene) -> SCNNode {
        let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

        let lineGeometry = SCNCylinder()
        lineGeometry.radius = CGFloat(lineRadius)
        lineGeometry.height = CGFloat(distance)
        lineGeometry.radialSegmentCount = 5
        // lineGeometry.firstMaterial!.diffuse.contents = GREEN

        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.position = midPosition
        lineNode.look (at: positionB, up: scene.rootNode.worldUp, localFront: lineNode.worldUp)
        return lineNode
    }
    
    func makeDotNode(position: SCNVector3, radius: CGFloat) -> SCNNode {
        let sphere = SCNSphere(radius: radius)
        let dotNode = SCNNode(geometry: sphere)
        dotNode.position = position
        return dotNode
    }
    
    func updateKeypoints(points: [Keypoint?]) {
        
        dotNodes.forEach { $0.removeFromParentNode() }
        dotNodes.removeAll()
        
        // (0<1, 0<1, 0<1) to scnvector3 (-studioSize<studioSize, -studioSize<studioSize, -studioSize<studioSize)
        let positions: [SCNVector3?] = points.map { point -> SCNVector3? in
            guard let point = point else { return nil }
            return point.yFlip.convertIntoSCNVector3(with: CGFloat(studioSize))
        }
        
        // create nodes if need
        positions.enumerated().forEach {
            let position: SCNVector3? = $0.element
            let dotNode: SCNNode
            if $0.offset < dotNodes.count {
                dotNode = dotNodes[$0.offset]
            } else {
                dotNode = makeDotNode(position: SCNVector3(0, 0, 0), radius: 0.2)
                dotNodes.append(dotNode)
                scene?.rootNode.addChildNode(dotNode)
            }
            if let p = position {
                dotNode.position = p
                dotNode.isHidden = false
            } else {
                dotNode.isHidden = true
            }
        }
    }
    
    func updateLines(lines :[HumanKeypoints.Line]) {
        guard let scene = scene else { return }
        
        lineNodes.forEach { $0.removeFromParentNode() }
        lineNodes.removeAll()
        
        let lines: [(SCNVector3, SCNVector3)] = lines.map { line -> (SCNVector3, SCNVector3) in
            guard let fromValue = line.from?.yFlip.convertIntoSCNVector3(with: CGFloat(studioSize)),
                  let toValue = line.to?.yFlip.convertIntoSCNVector3(with: CGFloat(studioSize)) else {
                return (SCNVector3Zero, SCNVector3Zero)
            }
            return (fromValue, toValue)
        }
        
        // create nodes if need and update it
        lines.enumerated().forEach {
            let line: (SCNVector3, SCNVector3) = $0.element
            let lineNode: SCNNode
            if $0.offset < lineNodes.count {
                lineNode = lineNodes[$0.offset]
            } else {
                lineNode = makeLineBetweenNodes(positionA: SCNVector3(0, 0, 0), positionB: SCNVector3(0, 0, 0), scene: scene)
                lineNodes.append(lineNode)
                scene.rootNode.addChildNode(lineNode)
            }
            
            updateLine(lineNode: lineNode, positionA: line.0, positionB: line.1, scene: scene)
        }
    }
    
    func updateLine(lineNode: SCNNode, positionA: SCNVector3, positionB: SCNVector3, scene: SCNScene) {
        let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

        let lineGeometry = SCNCylinder()
        lineGeometry.radius = CGFloat(lineRadius)
        lineGeometry.height = CGFloat(distance)
        lineGeometry.radialSegmentCount = 5
        // lineGeometry.firstMaterial!.diffuse.contents = GREEN

        lineNode.geometry = lineGeometry
        lineNode.position = midPosition
        lineNode.look (at: positionB, up: scene.rootNode.worldUp, localFront: lineNode.worldUp)
    }
    
    func updatePlane(points: [Keypoint]) {
        guard let scene = scene else { return }
        
        planeNodes.forEach { $0.removeFromParentNode() }
        planeNodes = []
        
        // (0<1, 0<1, 0<1) to scnvector3 (-studioSize<studioSize, -studioSize<studioSize, -studioSize<studioSize)
        let positions: [SCNVector3] = points.map { point -> SCNVector3 in
            return point.yFlip.convertIntoSCNVector3(with: CGFloat(studioSize))
        }
        
        let source = SCNGeometrySource(vertices: positions)
        
        let indices: [UInt16]
        if positions.count < 3 {
            indices = []
        } else {
            let uint16Indices: [UInt16] = (1..<positions.count-1).map { UInt16($0) }
            let idxs1: [UInt16] = uint16Indices.reduce([]) { r, i -> [UInt16] in r + [0, i, i+1] }
            let idxs2: [UInt16] = uint16Indices.reversed().reduce([]) { r, i -> [UInt16] in r + [i+1, i, 0] }
            indices = idxs1 + idxs2
        }
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        let node = SCNNode(geometry: geometry)
        node.opacity = 0.8
        
        planeNodes.append(node)
        scene.rootNode.addChildNode(node)
    }
}

extension Keypoint {
    func convertIntoSCNVector3(with size: CGFloat) -> SCNVector3 {
        guard let z = z else { return SCNVector3Zero }
        return SCNVector3(CGFloat(x)*size - size/2, (1.0 - CGFloat(y))*size - size/2, (1.0 - CGFloat(z))*size - size/2)
    }
}
