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
    
    let autoImportingImageFromAlbum = true
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
    var threshold: Float? {
        set {
            if let threshold = newValue {
                thresholdLabel?.text = String(format: "%.2f", threshold)
                thresholdSlider?.value = threshold
            } else {
                thresholdLabel?.text = "nil"
                thresholdSlider?.value = thresholdSlider?.minimumValue ?? 0.0
            }
        }
        get {
            return (thresholdSlider?.value == thresholdSlider?.minimumValue) ? nil : thresholdSlider?.value
        }
    }

    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var overlayLineDotView: PoseKeypointsDrawingView?
    @IBOutlet var partButtons: [UIButton]?
    @IBOutlet weak var thresholdLabel: UILabel?
    @IBOutlet weak var thresholdSlider: UISlider?
    
    // MARK: - ML Property
    let poseEstimator: PoseEstimator = OpenPosePoseEstimator()
    var outputHumans: [PoseEstimationOutput.Human] = [] {
        didSet {
            updateOverlayView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup UI
        setUpUI()

        // select
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
        
        threshold = 0.1
    }
    
    func updatePartButton(on targetPartName: String) {
        partButtons?.enumerated().forEach { offset, button in
            guard button.isEnabled, let partName = button.title(for: .normal) else { return }
            if partName.contains(targetPartName) {
                button.tintColor = UIColor.white
                button.backgroundColor = UIColor.systemBlue
            } else {
                button.tintColor = UIColor.systemBlue
                button.backgroundColor = UIColor.white
            }
        }
    }
    
    @objc func selectPart(_ button: UIButton) {
        guard let partName = button.title(for: .normal) else { return }
//        guard partName != "ALL" else {
//            let alert = UIAlertController(title: "Error", message: "Not support 'ALL' case on multi pose estimation", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
//            present(alert, animated: true)
//            return
//        }
        
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
    
    @IBAction func changeThreshold(_ sender: UISlider) {
        let threshold: Float? = sender.value == sender.minimumValue ? nil : sender.value
        if let threshold = threshold {
            thresholdLabel?.text = String(format: "%.2f", threshold)
        } else {
            thresholdLabel?.text = "nil"
        }
        
        let partIndex = selectedPartIndex
        guard let output = poseEstimator.postprocessOnLastOutput(with: threshold, on: partIndex) else { return }
        outputHumans = output.humans
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
        let input: PoseEstimationInput = .uiImage(uiImage: uiImage, cropArea: .squareAspectFill)
        let partIndex: Int? = selectedPartIndex
        let threshold: Float? = self.threshold
        let result: Result<PoseEstimationOutput, PoseEstimationError> = poseEstimator.inference(input, with: threshold, on: partIndex)
        switch (result) {
        case .success(let output):
            outputHumans = output.humans
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
