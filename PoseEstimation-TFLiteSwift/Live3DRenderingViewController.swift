//
//  Live3DRenderingViewController.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2021/03/13.
//  Copyright © 2021 Doyoung Gwak. All rights reserved.
//

import UIKit
import CoreMedia

class Live3DRenderingViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var shoulderFixingSwitch: UISwitch?
    @IBOutlet weak var previewView: UIView?
    @IBOutlet weak var outputRenderingView: Pose3DSceneView?
    @IBOutlet var topLabels: [UILabel]!
    
    // MARK: - VideoCapture Properties
    var videoCapture = VideoCapture()
    
    // MARK: - ML Property
    var isSinglePerson: Bool = true
    
    var preprocessOptions: PreprocessOptions {
        return PreprocessOptions(cropArea: .squareAspectFill)
    }
    var humanType: PostprocessOptions.HumanType = .singlePerson
    var postprocessOptions: PostprocessOptions {
        return PostprocessOptions(partThreshold: 0.5, // not use in 3D pose estimation
                                  bodyPart: nil,
                                  humanType: humanType)
    }
    
    // MARK: - ML Property
    lazy var poseEstimator: PoseEstimator = {
        var estimator = LiteBaseline3DPoseEstimator()
        estimator.delegate = self
        return estimator
    }()
    var humanKeypoints: HumanKeypoints? {
        didSet {
            DispatchQueue.main.async {
                self.outputRenderingView?.humanKeypoints = self.humanKeypoints
            }
        }
    }
    
    var isInferencing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup UI
        setUpScene()
        
        // setup camera
        setUpCamera()
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
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = previewView?.bounds ?? .zero
    }
    
    // MARK: - SetUp Video
    func setUpCamera() {
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: .vga640x480,
                           cameraPosition: .back,
                           videoGravity: .resizeAspectFill) { success in
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
    
    func setUpScene() {
        guard let outputRenderingView = outputRenderingView else { return }
        
        outputRenderingView.setupScene()
        outputRenderingView.showsStatistics = false
        
        outputRenderingView.setupBackgroundNodes()
    }
}

// MARK: - VideoCaptureDelegate
extension Live3DRenderingViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        guard !isInferencing else { return }
        isInferencing = true
        DispatchQueue(label: "inference").async { [weak self] in
            guard let self = self else { return }
            
            self.inference(with: pixelBuffer)
            
            self.isInferencing = false
        }
    }
}

extension Live3DRenderingViewController {
    func inference(with pixelBuffer: CVPixelBuffer) {
        let result: Result<PoseEstimationOutput, PoseEstimationError> = poseEstimator.inference(pixelBuffer, options: postprocessOptions)
        
        switch (result) {
        case .success(let output):
            if let human3d = output.humans3d.first ?? nil {
                let adjustMode = self.shoulderFixingSwitch?.isOn == true
                self.humanKeypoints = HumanKeypoints(human3d: human3d, adjustMode: adjustMode)
            } else {
                self.humanKeypoints = nil
            }
        case .failure(_):
            break
        }
    }
}

extension Live3DRenderingViewController: PoseEstimatorDelegate {
    func didEndInference(_ estimator: PoseEstimator, preprocessingTime: Double, inferenceTime: Double, postprocessingTime: Double) {
        DispatchQueue.main.async {
            let labelTexts = [
                "preproc: \(String(format: "%.0f", preprocessingTime*1000)) ms",
                "inference: \(String(format: "%.0f", inferenceTime*1000)) ms",
                "postproc: \(String(format: "%.0f", postprocessingTime*1000)) ms",
            ]
            
            zip(self.topLabels, labelTexts).forEach { $0.0.text = $0.1 }
        }
    }
}

private extension CGRect {
    func scaled(to scalingRatio: CGFloat) -> CGRect {
        return CGRect(x: origin.x * scalingRatio, y: origin.y * scalingRatio,
                      width: width * scalingRatio, height: height * scalingRatio)
    }
}
