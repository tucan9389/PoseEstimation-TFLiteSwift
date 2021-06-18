//
//  Live3DRenderingAndCapturingViewController.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2021/03/26.
//  Copyright © 2021 Doyoung Gwak. All rights reserved.
//

import UIKit
import CoreMedia
import Speech

class Live3DRenderingAndCapturingViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var speechStatusLabel: UILabel?
    @IBOutlet weak var previewView: UIView?
    @IBOutlet weak var outputRenderingView: Pose3DSceneView?
    @IBOutlet var capturedRenderingViews: [Pose3DSceneView]?
    @IBOutlet var capturedSimilarityLabels: [UILabel]?
    @IBOutlet weak var listeningButtonItem: UIBarButtonItem?
    
    // capturedRenderingViews
    
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
    let poseEstimator: PoseEstimator = Baseline3DPoseEstimator()
    var outputHuman: PoseEstimationOutput.Human3D? {
        didSet {
            DispatchQueue.main.async {
                self.outputRenderingView?.keypoints = self.outputHuman?.keypoints ?? []
                self.outputRenderingView?.lines = self.outputHuman?.lines ?? []
            }
        }
    }
    var capturedOutputHumans: [PoseEstimationOutput.Human3D] = []
    
    var isInferencing = false
    
    // MARK: - Speech
    var isListening = false {
        didSet {
            if isListening {
                speechStatusLabel?.text = "Listening... Say \"Capture\" or \"Stop\""
                speechStatusLabel?.backgroundColor = .systemRed
                speechStatusLabel?.textColor = .white
                speechStatusLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
            } else {
                speechStatusLabel?.text = "Not listening now."
                speechStatusLabel?.backgroundColor = .clear
                speechStatusLabel?.textColor = .none
                speechStatusLabel?.font = .systemFont(ofSize: 12, weight: .regular)
            }
        }
    }
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var capturedText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup UI
        setUpScene()
        
        // setup camera
        setUpCamera()
        
        // setup speech recognition
        setUpSpeechRecognition()
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
                           cameraPosition: .front,
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
        guard let outputRenderingView = outputRenderingView, let capturedRenderingViews = capturedRenderingViews else { return }
        
        outputRenderingView.setupScene()
        outputRenderingView.setupBackgroundNodes()
        
        capturedRenderingViews.forEach {
            $0.setupScene()
            $0.setupBackgroundNodes()
        }
    }
    
    func setUpSpeechRecognition() {
        isListening = false
    }
    
    @IBAction func didTapMic(_ sender: Any) {
        requestSpeechAuthorization { success in
            if success {
                if self.isListening {
                    self.stopToListen()
                } else {
                    self.startToListen()
                }
            }
        }
    }
    
    @IBAction func didTapCapture(_ sender: Any) {
        didTapCapture()
    }
    
    func didListen(text: String) {
        if text.lowercased() == "capture" || text.lowercased().starts(with: "c") || text.lowercased().contains("ture") {
            didListenCapture()
        } else if text.lowercased() == "stop" {
            didListenStop()
        }
    }
    
    func didListenCapture() {
        didTapCapture()
    }
    
    func didTapCapture() {
        print("capture!")
        guard let capturedHuman = outputHuman, let capturedRenderingViews = capturedRenderingViews else { return }
        capturedOutputHumans.insert(capturedHuman, at: 0)
        while capturedOutputHumans.count > capturedRenderingViews.count {
            capturedOutputHumans.removeLast()
        }
        for (capturedOutputHuman, capturedRenderingView) in zip(capturedOutputHumans, capturedRenderingViews) {
            capturedRenderingView.keypoints = capturedOutputHuman.keypoints
            capturedRenderingView.lines = capturedOutputHuman.lines
        }
    }
    
    
    func didListenStop() {
        stopToListen()
    }
    
    func startToListen() {
        isListening = true
        capturedText = ""
        
        if #available(iOS 13.0, *) {
            listeningButtonItem?.image = UIImage(systemName: "mic.fill")
        } else {
            // Fallback on earlier versions
            listeningButtonItem?.title = "🛑"
        }
        
        recordAndRecognizeSpeech()
    }
    
    func stopToListen() {
        isListening = false
        
        if #available(iOS 13.0, *) {
            listeningButtonItem?.image = UIImage(systemName: "mic.slash")
        } else {
            // Fallback on earlier versions
            listeningButtonItem?.title = "🎙"
        }
        
        cancelRecording()
    }
}

// MARK: - VideoCaptureDelegate
extension Live3DRenderingAndCapturingViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        guard !isInferencing else { return }
        isInferencing = true
        DispatchQueue(label: "inference").async { [weak self] in
            guard let self = self else { return }
            
            let poseResult = self.inference(with: pixelBuffer)
            self.matchPose(with: poseResult)
            
            self.isInferencing = false
        }
    }
}

extension Live3DRenderingAndCapturingViewController {
    func inference(with pixelBuffer: CVPixelBuffer) -> PoseEstimationOutput.Human3D? {
        let input: PoseEstimationInput = .pixelBuffer(pixelBuffer: pixelBuffer,
                                                      preprocessOptions: preprocessOptions,
                                                      postprocessOptions: postprocessOptions)
        let result: Result<PoseEstimationOutput, PoseEstimationError> = poseEstimator.inference(input)
        var poseResult: PoseEstimationOutput.Human3D?
        switch (result) {
        case .success(let output):
            poseResult = output.humans3d.first ?? nil
        case .failure(_):
            break
        }
        
        outputHuman = poseResult
        
        return poseResult
    }
    
    func matchPose(with precitedPoseResult: PoseEstimationOutput.Human3D?) {
        guard let precitedPoseResult = precitedPoseResult else {
            return
        }
        
        DispatchQueue.main.async {
            var highestSimliarityAndIndex: (similarity: CGFloat, index: Int?) = (0.0, nil)
            for (idx, capturedRenderingView) in (self.capturedRenderingViews ?? []).enumerated() {
                guard precitedPoseResult.lines.count == capturedRenderingView.lines.count else { continue }
                let similarity = precitedPoseResult.lines.matchVector(with: capturedRenderingView.lines)
                self.capturedSimilarityLabels?[idx].text = "similarity: \(String(format: "%.3f", similarity))"
                
                if highestSimliarityAndIndex.similarity < similarity {
                    highestSimliarityAndIndex.similarity = similarity
                    highestSimliarityAndIndex.index = idx
                }
                
                capturedRenderingView.layer.borderWidth = 2
                capturedRenderingView.layer.borderColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3).cgColor
            }
            
            let thresholdScore: CGFloat = 0.8
            if highestSimliarityAndIndex.similarity > thresholdScore, let highestIndex = highestSimliarityAndIndex.index {
                self.capturedRenderingViews?[highestIndex].layer.borderWidth = 4
                self.capturedRenderingViews?[highestIndex].layer.borderColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.5).cgColor
            }
        }
        
        
    }
}

extension Live3DRenderingAndCapturingViewController {
    func requestSpeechAuthorization(completion: @escaping ((Bool)->(Void))) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.listeningButtonItem?.isEnabled = true
                    completion(true)
                case .denied:
                    self.listeningButtonItem?.isEnabled = false
                    self.speechStatusLabel?.text = "User denied access to speech recognition"
                    self.speechStatusLabel?.backgroundColor = .systemBlue
                    completion(false)
                case .restricted:
                    self.listeningButtonItem?.isEnabled = false
                    self.speechStatusLabel?.text = "Speech recognition restricted on this device"
                    self.speechStatusLabel?.backgroundColor = .systemBlue
                    completion(false)
                case .notDetermined:
                    self.listeningButtonItem?.isEnabled = false
                    self.speechStatusLabel?.text = "Speech recognition not yet authorized"
                    self.speechStatusLabel?.backgroundColor = .systemBlue
                    completion(false)
                @unknown default:
                    completion(false)
                    return
                }
            }
        }
    }
    
    func cancelRecording() {
        recognitionTask?.finish()
        recognitionTask = nil
        
        // stop audio
        request.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    func recordAndRecognizeSpeech() {
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.sendAlert(title: "Speech Recognizer Error", message: "There has been an audio engine error.")
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            self.sendAlert(title: "Speech Recognizer Error", message: "Speech recognition is not supported for your current locale.")
            return
        }
        if !myRecognizer.isAvailable {
            self.sendAlert(title: "Speech Recognizer Error", message: "Speech recognition is not currently available. Check back at a later time.")
            // Recognizer is not available right now
            return
        }
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                
                let bestString = result.bestTranscription.formattedString
                var lastString: String = ""
                for segment in result.bestTranscription.segments {
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = String(bestString[indexTo...])
                }
                
                self.captureText(fullText: bestString, lastText: lastString)
            } else if let error = error {
                self.sendAlert(title: "Speech Recognizer Error", message: "There has been a speech recognition error.")
                print(error)
            }
        })
    }
    
    func captureText(fullText: String, lastText: String) {
        if capturedText.split(separator: " ").count != fullText.split(separator: " ").count ||
            (capturedText.split(separator: " ").count == fullText.split(separator: " ").count && capturedText.split(separator: " ").last ?? "" != lastText) {
            capturedText = fullText
            didListen(text: lastText)
        }
    }
    
    func sendAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

private extension CGRect {
    func scaled(to scalingRatio: CGFloat) -> CGRect {
        return CGRect(x: origin.x * scalingRatio, y: origin.y * scalingRatio,
                      width: width * scalingRatio, height: height * scalingRatio)
    }
}

private extension Array where Element == PoseEstimationOutput.Human3D.Line3D {
    func matchVector(with capturedLines: [PoseEstimationOutput.Human3D.Line3D]) -> CGFloat {
        let cosineSimilaries = zip(capturedLines, self).map { (capturedLine, predictedLine) -> CGFloat in
            let v1 = capturedLine.to - capturedLine.from
            let v2 = predictedLine.to - predictedLine.from
            return v1.product(rhs: v2) / (v1.distance * v2.distance)
        }
        let averageSilirarity = cosineSimilaries.reduce(0.0) { $0 + $1 } / CGFloat(cosineSimilaries.count)
        
        return averageSilirarity
    }
}
