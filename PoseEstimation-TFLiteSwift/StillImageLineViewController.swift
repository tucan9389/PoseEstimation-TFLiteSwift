//
//  StillImageLineViewController.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/20.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import UIKit
import Photos

class StillImageLineViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var overlayLineDotView: PoseKeypointsDrawingView?
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
    
    let autoImportingImageFromAlbum = true
    
    var isSinglePerson: Bool = true {
        didSet {
            humanTypeSegment?.selectedSegmentIndex = isSinglePerson ? 0 : 1
        }
    }
    lazy var partIndexes: [String: Int] = {
        var partIndexes: [String: Int] = [:]
        poseEstimator.partNames.enumerated().forEach { offset, partName in
            partIndexes[partName] = offset
        }
        return partIndexes
    }()
    var selectedPartName: String = "ALL"
    var selectedPartIndex: Int? {
        guard let partName = selectedPartName.components(separatedBy: "(").first else { return nil }
        return partIndexes[partName]
    }
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
    
    var preprocessOptions: PreprocessOptions {
        return PreprocessOptions(cropArea: .squareAspectFill)
    }
    var humanType: PostprocessOptions.HumanType {
        if isSinglePerson {
            return .singlePerson
        } else {
            return .multiPerson(pairThreshold: pairThreshold,
                                nmsFilterSize: pairNMSFilterSize,
                                maxHumanNumber: humanMaxNumber)
        }
    }
    var postprocessOptions: PostprocessOptions {
        return PostprocessOptions(partThreshold: partThreshold,
                                  bodyPart: selectedPartIndex,
                                  humanType: humanType)
    }
    
    // MARK: - ML Property
    let poseEstimator: PoseEstimator = LiteBaseline3DPoseEstimator()
    var outputHumans: [PoseEstimationOutput.Human2D] = [] {
        didSet {
            updateOverlayView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup UI
        setUpUI()

        // setup initial post-process params
        isSinglePerson = true   /// `multi-pose`
        partThreshold = 0.1     ///
        pairThreshold = 3.4     /// Only used on `multi-pose` mode. Before sort edges by cost, filter by pairThreshold for performance
        pairNMSFilterSize = 3   /// Only used on `multi-pose` mode. If 3, real could be 7X7 filter // (3●2+1)X(3●2+1)
        humanMaxNumber = nil    /// Only used on `multi-pose` mode. Not support yet
        
        select(on: "ALL")
        
        // import first image if autoImportingImageFromAlbum is true
        importFirstImageIfNeeded()
    }
    
    func setUpUI() {
        overlayLineDotView?.layer.borderColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.5).cgColor
        overlayLineDotView?.layer.borderWidth = 5
        
        let partNames = ["ALL"] + partIndexes.keys.sorted { (partIndexes[$0] ?? -1) < (partIndexes[$1] ?? -1) }
        partButtons?.enumerated().forEach { offset, button in
            if offset < partNames.count {
                if let partIndex = partIndexes[partNames[offset]] {
                    button.setTitle("\(partNames[offset])(\(partIndex))", for: .normal)
                } else {
                    button.setTitle("\(partNames[offset])", for: .normal)
                }
                
                button.isEnabled = true
                button.layer.cornerRadius = 5
                button.layer.borderWidth = 1
                button.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                button.setTitle("-", for: .normal)
                button.isEnabled = false
            }
            button.addTarget(self, action: #selector(selectPart), for: .touchUpInside)
        }
        
        partThresholdSlider?.isContinuous = false // `changeThreshold` will be called when touch up on slider
    }
    
    func updatePartButton(on targetPartName: String) {
        partButtons?.enumerated().forEach { offset, button in
            guard button.isEnabled, let partName = button.title(for: .normal) else { return }
            if partName.contains(targetPartName) {
                button.tintColor = UIColor.white
                button.backgroundColor = UIColor.systemBlue
            } else {
                button.tintColor = UIColor.systemBlue
                button.backgroundColor = UIColor.clear
            }
        }
    }
    
    @objc func selectPart(_ button: UIButton) {
        guard let partName = button.title(for: .normal) else { return }
        
        select(on: partName)
        if let image = imageView?.image {
            self.inference(with: image)
        }
    }
    
    func select(on partName: String) {
        selectedPartName = partName
        updatePartButton(on: partName)
        updateOverlayView()
    }
    
    func updateOverlayView() {
        DispatchQueue.main.async {
            self.overlayLineDotView?.alpha = 1
            
            if let partOffset = self.partIndexes[self.selectedPartName] {
                self.overlayLineDotView?.lines = []
                self.overlayLineDotView?.keypoints = self.outputHumans.map { $0.keypoints[partOffset] }
            } else { // ALL case
                self.overlayLineDotView?.lines = self.outputHumans.reduce([]) { $0 + $1.lines }
                self.overlayLineDotView?.keypoints = self.outputHumans.reduce([]) { $0 + $1.keypoints }
            }
        }
    }
    
    @IBAction func importImage(_ sender: Any) {
        let pickerVC = UIImagePickerController()
        pickerVC.delegate = self
        navigationController?.present(pickerVC, animated: true)
    }
    
    @IBAction func export(_ sender: Any) {
        guard let overlayViewRect = overlayLineDotView?.frame,
            let directoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = directoryPath.appendingPathComponent("pose-linedot-demo.jpeg")
        let image = view.uiImage(in: overlayViewRect)
        let imageData = image.jpegData(compressionQuality: 0.95)
        try? imageData?.write(to: fileURL)
        let vc = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        present(vc, animated: true)
    }
    
    @IBAction func didChangeHumanType(_ sender: UISegmentedControl) {
        isSinglePerson = (sender.selectedSegmentIndex == 0)
        updateOverlayViewWithOnlyPostprocess()
    }
    
    @IBAction func didChangeDimension(_ sender: UISegmentedControl) {
        // <#TODO#>
    }
    
    @IBAction func didChangePartThreshold(_ sender: UISlider) {
        partThreshold = (sender.value == sender.minimumValue) ? nil : sender.value
        updateOverlayViewWithOnlyPostprocess()
    }
    
    @IBAction func didChangePairThreshold(_ sender: UISlider) {
        pairThreshold = (sender.value == sender.minimumValue) ? nil : sender.value
        updateOverlayViewWithOnlyPostprocess()
    }
    
    @IBAction func didChangePairNMSFilterSize(_ sender: UIStepper) {
        pairNMSFilterSize = Int(sender.value)
        updateOverlayViewWithOnlyPostprocess()
    }
    
    @IBAction func didChangeHumanMaxNumber(_ sender: UIStepper) {
        humanMaxNumber = (sender.value == sender.minimumValue) ? nil : Int(sender.value)
        updateOverlayViewWithOnlyPostprocess()
    }
    
    func updateOverlayViewWithOnlyPostprocess() {
        guard let output = poseEstimator.postprocessOnLastOutput(options: postprocessOptions) else { return }
        outputHumans = output.humans2d.compactMap { $0 }
    }
}

extension StillImageLineViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickedImage = info[.originalImage] as? UIImage else {
            imageView?.image = nil
            picker.dismiss(animated: true)
            return
        }
        
        picker.dismiss(animated: true)
        
        imageView?.image = pickedImage
        inference(with: pickedImage)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension StillImageLineViewController: UINavigationControllerDelegate { }

extension StillImageLineViewController {
    func inference(with uiImage: UIImage) {
        let result: Result<PoseEstimationOutput, PoseEstimationError> = poseEstimator.inference(uiImage, options: postprocessOptions)
        switch (result) {
        case .success(let output):
            outputHumans = output.humans2d.compactMap { $0 }
            // modelOutput = output.outputs.first
        case .failure(_):
            break
        }
    }
}

extension StillImageLineViewController {
    func importFirstImageIfNeeded() {
        guard autoImportingImageFromAlbum else { return }
        
        let fetchOptions = PHFetchOptions()
        let descriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchOptions.sortDescriptors = [descriptor]

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        
//        let asset = fetchResult.object(at: 5)
        guard let asset = fetchResult.lastObject else {
            return
        }

        let scale = UIScreen.main.scale
        let size = CGSize(width: (imageView?.frame.width ?? 0) * scale,
                          height: (imageView?.frame.height ?? 0) * scale)
        
        let options = PHImageRequestOptions()
        options.resizeMode = .exact
        options.deliveryMode = .opportunistic

        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { (image, info) in
            DispatchQueue.main.async {
                guard (info?[PHImageResultIsDegradedKey] as AnyObject).boolValue == false,
                    let image = image else { return }
                print(image.size)
                self.imageView?.image = image
                self.inference(with: image)
            }
        }
    }
}
