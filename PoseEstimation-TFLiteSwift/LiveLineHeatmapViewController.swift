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
//  LiveLineHeatmapViewController.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/05/09.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import UIKit
import CoreMedia

class LiveLineHeatmapViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var previewView: UIView?
    @IBOutlet weak var overlayGuideView: UIView?
    @IBOutlet weak var lineDotView: PoseKeypointsDrawingView?
    @IBOutlet weak var heatmapView: PoseConfidenceMapDrawingView?
    
    @IBOutlet weak var humanTypeSegment: UISegmentedControl?
    @IBOutlet weak var dimensionSegment: UISegmentedControl?
    @IBOutlet var partButtons: [UIButton]?
    @IBOutlet weak var partThresholdLabel: UILabel?
    @IBOutlet weak var partThresholdSlider: UISlider?
    @IBOutlet weak var pairThresholdLabel: UILabel?
    @IBOutlet weak var pairThresholdSlider: UISlider?
    @IBOutlet weak var pairNMSFilterSizeLabel: UILabel?
    @IBOutlet weak var pairNMSFilterSizeStepper: UIStepper?
    @IBOutlet weak var humanMaxNumberLabel: UILabel?
    @IBOutlet weak var humanMaxNumberStepper: UIStepper?
    
    var overlayGuideViewRelativeRect: CGRect = .zero
    var pixelBufferWidth: CGFloat = 0
    
    var isSinglePerson: Bool = true {
        didSet {
            humanTypeSegment?.selectedSegmentIndex = isSinglePerson ? 0 : 1
        }
    }
//    lazy var partIndexes: [String: Int] = {
//        var partIndexes: [String: Int] = [:]
//        poseEstimator.partNames.enumerated().forEach { offset, partName in
//            partIndexes[partName] = offset
//        }
//        return partIndexes
//    }()
//    var selectedPartName: String = "ALL"
//    var selectedPartIndex: Int? {
//        guard let partName = selectedPartName.components(separatedBy: "(").first else { return nil }
//        return partIndexes[partName]
//    }
    var partThreshold: Float? {
        didSet {
            let (slider, label, value) = (partThresholdSlider, partThresholdLabel, partThreshold)
            if let slider = slider { slider.value = value ?? slider.minimumValue }
            if let label = label { label.text = value.labelString }
        }
    }
    var pairThreshold: Float? {
        didSet {
            let (slider, label, value) = (pairThresholdSlider, pairThresholdLabel, pairThreshold)
            if let slider = slider { slider.value = value ?? slider.minimumValue }
            if let label = label { label.text = value.labelString }
        }
    }
    var pairNMSFilterSize: Int = 3 {
        didSet {
            let (stepper, label, value) = (pairNMSFilterSizeStepper, pairNMSFilterSizeLabel, pairNMSFilterSize)
            if let stepper = stepper { stepper.value = Double(value) }
            if let label = label { label.text = value.labelString }
        }
    }
    var humanMaxNumber: Int? = 5 {
        didSet {
            let (stepper, label, value) = (humanMaxNumberStepper, humanMaxNumberLabel, humanMaxNumber)
            if let stepper = stepper {
                guard Int(stepper.minimumValue) != value else { humanMaxNumber = nil; return }
                if let value = value { stepper.value = Double(value) }
                else { stepper.value = stepper.minimumValue }
            }
            if let label = label { label.text = value.labelString }
        }
    }
    
    // MARK: - VideoCapture Properties
    var videoCapture = VideoCapture()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup camera
        setUpCamera()
        
        // setup UI
        setUpUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        videoCapture.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoCapture.stop()
    }
    
    override func viewDidLayoutSubviews() {
        resizePreviewLayer()
        
        let previewViewRect = previewView?.frame ?? .zero
        let overlayViewRect = overlayGuideView?.frame ?? .zero
        let relativeOrigin = CGPoint(x: overlayViewRect.origin.x - previewViewRect.origin.x,
                                     y: overlayViewRect.origin.y - previewViewRect.origin.y)
        overlayGuideViewRelativeRect = CGRect(origin: relativeOrigin, size: overlayViewRect.size)
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = previewView?.bounds ?? .zero
    }
    
    // MARK: - SetUp Video
    func setUpCamera() {
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            DispatchQueue.main.async {
                if success {
                    // add preview view on the layer
                    if let previewLayer = self.videoCapture.previewLayer {
                        self.previewView?.layer.addSublayer(previewLayer)
                        self.resizePreviewLayer()
                    }
                    
                    // start video preview when setup is done
                    self.videoCapture.start()
                }
            }
        }
    }
    
    func setUpUI() {
        overlayGuideView?.layer.borderColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.5).cgColor
        overlayGuideView?.layer.borderWidth = 5
    }
    
    @objc func selectPart(_ button: UIButton) {
        guard let partName = button.title(for: .normal) else { return }
        
        select(on: partName)
    }
    
    func select(on partName: String) {
//        selectedPartName = partName
//        updatePartButton(on: partName)
    }
    
    @IBAction func didChangeHumanType(_ sender: UISegmentedControl) {
        isSinglePerson = (sender.selectedSegmentIndex == 0)
    }
    
    @IBAction func didChangeDimension(_ sender: UISegmentedControl) {
        // <#TODO#>
    }
    
    @IBAction func didChangedPartThreshold(_ sender: UISlider) {
        partThreshold = (sender.value == sender.minimumValue) ? nil : sender.value
    }
    
    @IBAction func didChangePairThreshold(_ sender: UISlider) {
        pairThreshold = (sender.value == sender.minimumValue) ? nil : sender.value
    }
    
    @IBAction func didChangePairNMSFilterSize(_ sender: UIStepper) {
        pairNMSFilterSize = Int(sender.value)
    }
    
    @IBAction func didChangeHumanMaxNumber(_ sender: UIStepper) {
        humanMaxNumber = (sender.value == sender.minimumValue) ? nil : Int(sender.value)
    }
}

// MARK: - VideoCaptureDelegate
extension LiveLineHeatmapViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        // inference(with: pixelBuffer)
    }
}
