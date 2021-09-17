//
//  StillImage3DRenderingViewController.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2021/03/13.
//  Copyright © 2021 Doyoung Gwak. All rights reserved.
//

import UIKit
import Photos

class StillImage3DRenderingViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var outputRenderingView: Pose3DSceneView?
    
    //
    let autoImportingImageFromAlbum = true
    
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
    let poseEstimator: PoseEstimator = LiteBaseline3DPoseEstimator()
    var humanKeypoints: HumanKeypoints? {
        didSet {
            DispatchQueue.main.async {
                self.outputRenderingView?.humanKeypoints = self.humanKeypoints
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup UI
        setUpScene()
        
        // import first image if autoImportingImageFromAlbum is true
        importFirstImageIfNeeded()
    }
    
    func setUpScene() {
        guard let outputRenderingView = outputRenderingView else { return }
        
        outputRenderingView.setupScene()
        
        outputRenderingView.setupBackgroundNodes()
    }
    
    @IBAction func importImage(_ sender: Any) {
        let pickerVC = UIImagePickerController()
        pickerVC.delegate = self
        navigationController?.present(pickerVC, animated: true)
    }
}

extension StillImage3DRenderingViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickedImage = info[.originalImage] as? UIImage else {
            imageView?.image = nil
            picker.dismiss(animated: true)
            return
        }
        
        picker.dismiss(animated: true)
        
        imageView?.image = pickedImage
        DispatchQueue(label: "inference").async {
            self.inference(with: pickedImage)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension StillImage3DRenderingViewController: UINavigationControllerDelegate { }

extension StillImage3DRenderingViewController {
    func inference(with uiImage: UIImage) {
        let result: Result<PoseEstimationOutput, PoseEstimationError> = poseEstimator.inference(uiImage, options: postprocessOptions)
        switch (result) {
        case .success(let output):
            if let human3d = output.humans3d.first ?? nil {
                self.humanKeypoints = HumanKeypoints(human3d: human3d)
            } else {
                self.humanKeypoints = nil
            }
        case .failure(_):
            break
        }
    }
}

extension StillImage3DRenderingViewController {
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

        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .default, options: options) { (image, info) in
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
