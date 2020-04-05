//
//  PoseKeypointsDrawingView.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/20.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import UIKit

class PoseKeypointsDrawingView: UIView {
    typealias CGLine = (from: CGPoint, to: CGPoint)
    
    var result: PoseEstimationOutput? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    var threshold: CGFloat?
    
    override func draw(_ rect: CGRect) {
        guard let keypoints = result?.filteredKeypoints(with: threshold),
            let lines = result?.filteredLines(with: threshold) else { return }
        
        lines.forEach { line in
            let fromPoint = line.from.position.scaled(to: frame.size)
            let toPoint = line.to.position.scaled(to: frame.size)
            let cgLine = (from: fromPoint, to: toPoint)
            drawLine(with: cgLine)
        }
        
        keypoints.forEach { keypoint in
            let point = keypoint.position.scaled(to: frame.size)
            drawDot(at: point)
        }
    }
    
    func drawDot(at point: CGPoint) {
        let dotRect = CGRect(x: point.x - DrawingConstant.Dot.radius / 2, y: point.y - DrawingConstant.Dot.radius / 2,
                             width: DrawingConstant.Dot.radius, height: DrawingConstant.Dot.radius)
        let dotPath = UIBezierPath(ovalIn: dotRect)

        DrawingConstant.Dot.fillColor.setFill()
        dotPath.fill()
    }
    
    func drawLine(with line: CGLine) {
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: line.from.x, y: line.from.y))
        linePath.addLine(to: CGPoint(x: line.to.x, y: line.to.y))
        linePath.close()

        linePath.lineWidth = DrawingConstant.Line.width
        DrawingConstant.Line.color.setStroke()

        linePath.stroke()
    }
}

private extension PoseKeypointsDrawingView {
    enum DrawingConstant {
        enum Dot {
            static let radius: CGFloat = 5
            static let borderWidth: CGFloat = 2
            static let borderColor: UIColor = UIColor.red
            static let fillColor: UIColor = UIColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1)
        }
        enum Line {
            static let width: CGFloat = 2
            static let color: UIColor = UIColor(red: 0.5, green: 0.1, blue: 0.1, alpha: 1)
        }
    }
}

private extension CGPoint {
    func scaled(to ratioSize: CGSize) -> CGPoint {
        return CGPoint(x: x * ratioSize.width, y: y * ratioSize.height)
    }
}
