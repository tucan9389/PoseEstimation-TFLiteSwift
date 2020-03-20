//
//  ViewController.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/14.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import UIKit
import CoreMedia

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var previewView: UIView?
    
    // MARK: - VideoCapture Properties
    var videoCapture: VideoCapture!
    
    // MARK: - ML Property
    let poseEstimator: PoseEstimator = PoseNetPoseEstimator()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup camera
        setUpCamera()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCapture.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }
    
    // MARK: - SetUp Video
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            
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
    
    override func viewDidLayoutSubviews() {
        // super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = previewView?.bounds ?? .zero
    }
}

// MARK: - VideoCaptureDelegate
extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        // the captured image from camera is contained on pixelBuffer
        
        let result: Result<Keypoints, PoseEstimationError> = poseEstimator.inference(with: pixelBuffer)
        print(result)
    }
}
