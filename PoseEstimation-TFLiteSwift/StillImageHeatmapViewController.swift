//
//  StillImageHeatmapViewController.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/04/28.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import UIKit
import Photos
import TFLiteSwift_Vision

class StillImageHeatmapViewController: UIViewController {

    let autoImportingImageFromAlbum = true
    
    lazy var partIndexes: [String: Int] = {
        var partIndexes: [String: Int] = [:]
        poseEstimator.partNames.enumerated().forEach { offset, partName in
            partIndexes[partName] = offset
        }
        return partIndexes
    }()
    lazy var pairIndexes: [String: Int] = {
        var pairIndexes: [String: Int] = [:]
        poseEstimator.pairNames?.enumerated().forEach { offset, pairName in
            pairIndexes[pairName] = offset
        }
        return pairIndexes
    }()
    
    enum SelectedMap {
        case confidenceMap(part: String)
        case paf(pair: String) // part affinity field
        
        func isConfidenceMap() -> Bool {
            if case .confidenceMap = self { return true }
            else { return false }
        }
        func isPAF() -> Bool {
            if case .paf = self { return true }
            else { return false }
        }
    }
    
    var selectedChannel: SelectedMap = .confidenceMap(part: "ALL")

    // MARK: - IBOutlets
    @IBOutlet weak var topPaletteView: UIView?
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var overlayHeatmapView: PoseConfidenceMapDrawingView?
    @IBOutlet var partButtons: [UIButton]?
    @IBOutlet var pairButtons: [UIButton]?
    @IBOutlet weak var pafSegment: UISegmentedControl?
    
    // MARK: - ML Property
    let poseEstimator: PoseEstimator = LiteBaseline3DPoseEstimator()
    var modelOutput: [TFLiteFlatArray]? {
        didSet {
            updateHeatmapOverlayView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup UI
        setUpUI()

        // select
        if let button = partButtons?.first {
            selectChannel(button)
        }
        
        // import first image if autoImportingImageFromAlbum is true
        importFirstImageIfNeeded()
    }
    
    func setUpUI() {
        overlayHeatmapView?.layer.borderColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.5).cgColor
        overlayHeatmapView?.layer.borderWidth = 5
        
        let partNames = ["ALL"] + partIndexes.keys.sorted { (partIndexes[$0] ?? -1) < (partIndexes[$1] ?? -1) }
        partButtons?.enumerated().forEach { buttonIndex, button in
            if buttonIndex < partNames.count {
                if let partIndex = partIndexes[partNames[buttonIndex]] {
                    button.setTitle("\(partNames[buttonIndex])(\(partIndex))", for: .normal)
                } else {
                    button.setTitle("\(partNames[buttonIndex])", for: .normal)
                }
                
                button.isEnabled = true
                button.layer.cornerRadius = 5
                button.layer.borderWidth = 1
                button.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                button.setTitle("-", for: .normal)
                button.isEnabled = false
            }
            button.addTarget(self, action: #selector(selectChannel), for: .touchUpInside)
        }
        
        let pairNames = ["ALL"] + pairIndexes.keys.sorted { (pairIndexes[$0] ?? -1) < (pairIndexes[$1] ?? -1) }
        pairButtons?.enumerated().forEach { buttonIndex, button in
            if buttonIndex < pairNames.count {
                if let pairIndex = pairIndexes[pairNames[buttonIndex]] {
                    button.setTitle("\(pairNames[buttonIndex])(\(pairIndex))", for: .normal)
                } else {
                    button.setTitle("\(pairNames[buttonIndex])", for: .normal)
                }
                
                button.isEnabled = true
                button.layer.cornerRadius = 5
                button.layer.borderWidth = 1
                button.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                button.setTitle("-", for: .normal)
                button.isEnabled = false
            }
            button.addTarget(self, action: #selector(selectChannel), for: .touchUpInside)
        }
        
        pafSegment?.isEnabled = (poseEstimator.pairNames != nil)
    }
    
    func updateChannelButton(with targetButtonName: String?, on buttons: [UIButton]?) {
        buttons?.enumerated().forEach { offset, button in
            guard button.isEnabled, let buttonName = button.title(for: .normal) else { return }
            if let targetPartName = targetButtonName,
                buttonName.contains(targetPartName) {
                button.tintColor = UIColor.white
                button.backgroundColor = UIColor.systemBlue
            } else {
                button.tintColor = UIColor.systemBlue
                button.backgroundColor = UIColor.clear
            }
        }
    }
    
    @IBAction func didChangePAF(_ sender: Any) {
        if case .paf = selectedChannel {
            updateHeatmapOverlayView()
        } else {
            guard let allButton = pairButtons?.first else { return }
            selectChannel(allButton)
        }
    }
    
    @objc func selectChannel(_ button: UIButton) {
        guard let buttonTitle = button.title(for: .normal) else { return }
        
        if partButtons?.contains(button) == true {
            let partName = buttonTitle.components(separatedBy: "(").first ?? buttonTitle
            updateChannelButton(with: partName, on: partButtons)
            updateChannelButton(with: nil, on: pairButtons)
            selectedChannel = .confidenceMap(part: partName)
            UIView.animate(withDuration: 0.23) { self.pafSegment?.alpha = 0.5 }
        } else if pairButtons?.contains(button) == true {
            let pairName = buttonTitle.components(separatedBy: "(").first ?? buttonTitle
            updateChannelButton(with: nil, on: partButtons)
            updateChannelButton(with: pairName, on: pairButtons)
            selectedChannel = .paf(pair: pairName)
            UIView.animate(withDuration: 0.23) { self.pafSegment?.alpha = 1.0 }
        }
        
        updateHeatmapOverlayView()
    }
    
    func updateHeatmapOverlayView() {
        DispatchQueue.main.async {
            if case .confidenceMap(let partName) = self.selectedChannel {
                if let partIndex = self.partIndexes[partName] {
                    self.overlayHeatmapView?.outputChannelIndexes = [partIndex]
                } else {
                    let startIndex = 0
                    let endIndex = self.partIndexes.count - 1
                    self.overlayHeatmapView?.outputChannelIndexes = Array(startIndex..<endIndex)
                }
            } else if case .paf(let pairName) = self.selectedChannel {
                if self.pafSegment?.selectedSegmentIndex == 0 { // x
                    if let pairIndex = self.pairIndexes[pairName] {
                        let channelIndex = self.partIndexes.count + pairIndex*2 + 0
                        self.overlayHeatmapView?.outputChannelIndexes = [channelIndex]
                    } else {
                        let startIndex = self.partIndexes.count
                        let endIndex = startIndex + self.pairIndexes.count * 2
                        self.overlayHeatmapView?.outputChannelIndexes = Array(startIndex..<endIndex).filter { $0 % 2 == 1 }
                    }
                } else { // y
                    if let pairIndex = self.pairIndexes[pairName] {
                        let channelIndex = self.partIndexes.count + pairIndex*2 + 1
                        self.overlayHeatmapView?.outputChannelIndexes = [channelIndex]
                    } else {
                        let startIndex = self.partIndexes.count
                        let endIndex = startIndex + self.pairIndexes.count * 2
                        self.overlayHeatmapView?.outputChannelIndexes = Array(startIndex..<endIndex).filter { $0 % 2 == 0 }
                    }
                }
            }
            self.overlayHeatmapView?.output = self.modelOutput?.first
        }
    }
    
    @IBAction func importImage(_ sender: Any) {
        let pickerVC = UIImagePickerController()
        pickerVC.delegate = self
        navigationController?.present(pickerVC, animated: true)
    }
    
    @IBAction func export(_ sender: Any) {
        guard let topPaletteViewRect = topPaletteView?.frame,
            let overlayViewRect = overlayHeatmapView?.frame,
            let directoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = directoryPath.appendingPathComponent("pose-heatmap-demo.jpeg")
        let rect = CGRect(x: topPaletteViewRect.origin.x, y: topPaletteViewRect.origin.y,
                          width: overlayViewRect.width, height: topPaletteViewRect.height + overlayViewRect.height)
        let image = view.uiImage(in: rect)
        let imageData = image.jpegData(compressionQuality: 0.95)
        try? imageData?.write(to: fileURL)
        let vc = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        present(vc, animated: true)
    }
}

extension StillImageHeatmapViewController: UIImagePickerControllerDelegate {
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

extension StillImageHeatmapViewController: UINavigationControllerDelegate { }

extension StillImageHeatmapViewController {
    func inference(with uiImage: UIImage) {
        // let preprocessOptions = PreprocessOptions(cropArea: .squareAspectFill)
        let humanType: PostprocessOptions.HumanType = .multiPerson(pairThreshold: 0.2,
                                                                   nmsFilterSize: 5,
                                                                   maxHumanNumber: nil)
        let postprocessOptions = PostprocessOptions(partThreshold: 0.14,
                                                    bodyPart: nil,
                                                    humanType: humanType)
        let result: Result<PoseEstimationOutput, PoseEstimationError> = poseEstimator.inference(uiImage, options: postprocessOptions)
        switch (result) {
        case .success(let output):
            modelOutput = output.outputs
        case .failure(_):
            break
        }
    }
}

extension StillImageHeatmapViewController {
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
