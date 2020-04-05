//
//  LiveImageViewController.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import UIKit
import CoreMedia

class LiveImageViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var previewView: UIView?
    @IBOutlet weak var overlayView: PoseKeypointsDrawingView?
    var overlayViewRelativeRect: CGRect = .zero
    
    @IBOutlet weak var thresholdValueLabel: UILabel?
    @IBOutlet weak var thresholdValueSlider: UISlider?
    
    var threshold: Float? {
        guard let slider = thresholdValueSlider,
            slider.value != slider.minimumValue else { return nil }
        return slider.value
    }
    
    // MARK: - VideoCapture Properties
    var videoCapture = VideoCapture()
    
    // MARK: - ML Property
    let poseEstimator: PoseEstimator = PoseNetPoseEstimator()

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
        overlayView?.layer.borderColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.5).cgColor
        overlayView?.layer.borderWidth = 5
        
        thresholdValueSlider?.value = thresholdValueSlider?.minimumValue ?? 0
    }
    
    override func viewDidLayoutSubviews() {
        resizePreviewLayer()
        
        let previewViewRect = previewView?.frame ?? .zero
        let overlayViewRect = overlayView?.frame ?? .zero
        let relativeOrigin = CGPoint(x: overlayViewRect.origin.x - previewViewRect.origin.x,
                                     y: overlayViewRect.origin.y - previewViewRect.origin.y)
        overlayViewRelativeRect = CGRect(origin: relativeOrigin, size: overlayViewRect.size)
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = previewView?.bounds ?? .zero
    }
    
    @IBAction func didChangedThresholdValue(_ sender: UISlider) {
        if let threshold = threshold {
            thresholdValueLabel?.text = String(format: "%.2f", threshold)
        } else {
            thresholdValueLabel?.text = "nil"
        }
    }
}

// MARK: - VideoCaptureDelegate
extension LiveImageViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        inference(with: pixelBuffer)
    }
}

extension LiveImageViewController {
    func inference(with pixelBuffer: CVPixelBuffer) {
        let scalingRatio = pixelBuffer.size.width / overlayViewRelativeRect.width
        let targetAreaRect = overlayViewRelativeRect.scaled(to: scalingRatio)
        let input: PoseEstimationInput = .pixelBuffer(pixelBuffer: pixelBuffer, cropArea: .customAspectFill(rect: targetAreaRect))
        let result: Result<PoseEstimationOutput, PoseEstimationError> = poseEstimator.inference(with: input)
        
        switch (result) {
        case .success(let output):
            DispatchQueue.main.async {
                let threshold = self.threshold
                let lines = output.filteredLines(with: threshold)
                let keypoints = output.filteredKeypoints(with: threshold)
                self.overlayView?.lines = lines
                self.overlayView?.keypoints = keypoints
            }
        case .failure(_):
            break
        }
        
    }
}

private extension CGRect {
    func scaled(to scalingRatio: CGFloat) -> CGRect {
        return CGRect(x: origin.x * scalingRatio, y: origin.y * scalingRatio,
                      width: width * scalingRatio, height: height * scalingRatio)
    }
}
