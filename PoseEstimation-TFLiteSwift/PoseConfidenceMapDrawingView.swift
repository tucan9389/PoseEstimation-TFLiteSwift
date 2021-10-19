//
//  PoseConfidenceMapDrawingView.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/04/24.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import UIKit
import TFLiteSwift_Vision

class PoseConfidenceMapDrawingView: UIView {
    typealias CGLine = (from: CGPoint, to: CGPoint)
    var outputChannelIndexes: [Int] = [0]
    var output: TFLiteFlatArray? {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let output = output else { return }
        
        let (rowCount, colCount) = (output.dimensions[1], output.dimensions[2])
        let (width, height) = (frame.width, frame.height)
        let (oneAreaWidth, oneAreaHeight) = (width/CGFloat(colCount), height/CGFloat(rowCount))
        
        // top-left is (0,0)
        for row in 0..<rowCount {
            for col in 0..<colCount {
                var componentOfVector = outputChannelIndexes.reduce(0.0) { value, outputChannelIndex in
                    return value + output[0, row, col, outputChannelIndex]
                }
                componentOfVector = min(max(componentOfVector, -1.0), 1.0) // -1.0 ~ 1.0
                let drawingAreaRect = CGRect(x: oneAreaWidth*CGFloat(col), y: oneAreaHeight*CGFloat(row),
                                             width: oneAreaWidth, height: oneAreaHeight)
                let areaFillColor = DrawingConstant.Area.areaColor(CGFloat(componentOfVector))
                drawRect(with: drawingAreaRect, fillColor: areaFillColor)
            }
        }
    }
    
    func drawRect(with rect: CGRect, fillColor: UIColor) {
        guard let startingPoint = rect.points.first else { return }
        let rectPath = UIBezierPath()
        rectPath.move(to: startingPoint)
        for point in rect.points[1...] {
            rectPath.addLine(to: point)
        }
        rectPath.addLine(to: startingPoint)
        rectPath.close()
        
        // draw line
        rectPath.lineWidth = (frame.width > 200) ? DrawingConstant.Line.width : 0
        DrawingConstant.Area.lineColor.setStroke()
        rectPath.stroke()
        // draw color in rect
        fillColor.setFill()
        rectPath.fill()
    }
}

private extension PoseConfidenceMapDrawingView {
    enum DrawingConstant {
        enum Line {
            static let width: CGFloat = 0.5
            static let color: UIColor = UIColor(red: 0.5, green: 0.1, blue: 0.1, alpha: 1)
        }
        enum Area {
            static let lineColor: UIColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
            static func areaColor(_ componentOfVector: CGFloat) -> UIColor {
                if componentOfVector < 0 {
                    return areaNegativeColor(componentOfVector)
                } else {
                    return areaPositiveColor(componentOfVector)
                }
            }
            private static let baisAlpha: CGFloat = 0.5 // 0.85
            private static func areaPositiveColor(_ magnitude: CGFloat) -> UIColor {
                let colorValue = min(max(magnitude, 0.0), 1.0)
                let alphaValue = (1-baisAlpha)*colorValue + baisAlpha
                return UIColor(red: colorValue, green: 0, blue: 0, alpha: alphaValue)
            }
            private static func areaNegativeColor(_ magnitude: CGFloat) -> UIColor {
                let colorValue = min(max(abs(magnitude), 0.0), 1.0)
                let alphaValue = (1-baisAlpha)*colorValue + baisAlpha
                return UIColor(red: 0, green: colorValue, blue: 0, alpha: alphaValue)
            }
        }
    }
}

private extension CGPoint {
    func scaled(to ratioSize: CGSize) -> CGPoint {
        return CGPoint(x: x * ratioSize.width, y: y * ratioSize.height)
    }
}

private extension CGRect {
    var points: [CGPoint] {
        return [
            origin,
            CGPoint(x: origin.x + width, y: origin.y),
            CGPoint(x: origin.x + width, y: origin.y + height),
            CGPoint(x: origin.x, y: origin.y + height)
        ]
    }
}
