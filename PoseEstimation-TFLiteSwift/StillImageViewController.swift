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
//  StillImageViewController.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/20.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import UIKit
import Photos

class StillImageViewController: UIViewController {
    
    let autoImportingImageFromAlbum = true

    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var overlayView: PoseKeypointsDrawingView?
    
    // MARK: - ML Property
    let poseEstimator: PoseEstimator = PoseNetPoseEstimator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup UI
        setUpUI()
        
        // import first image if autoImportingImageFromAlbum is true
        importFirstImageIfNeeded()
    }
    
    func setUpUI() {
        overlayView?.layer.borderColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.5).cgColor
        overlayView?.layer.borderWidth = 5
    }
    
    @IBAction func importImage(_ sender: Any) {
        let pickerVC = UIImagePickerController()
        pickerVC.delegate = self
        navigationController?.present(pickerVC, animated: true)
    }
}

extension StillImageViewController: UIImagePickerControllerDelegate {
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

extension StillImageViewController: UINavigationControllerDelegate { }

extension StillImageViewController {
    func inference(with uiImage: UIImage) {
        let input: PoseEstimationInput = .uiImage(uiImage: uiImage, cropArea: .squareAspectFill)
        let result: Result<PoseEstimationOutput, PoseEstimationError> = poseEstimator.inference(with: input)
        switch (result) {
        case .success(let output):
            let lines = output.lines
            let keypoints = output.keypoints
            DispatchQueue.main.async {
                self.overlayView?.lines = lines
                self.overlayView?.keypoints = keypoints
            }
        case .failure(_):
            break
        }
        
    }
}

extension StillImageViewController {
    func importFirstImageIfNeeded() {
        guard autoImportingImageFromAlbum else { return }
        
        let fetchOptions = PHFetchOptions()
        let descriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchOptions.sortDescriptors = [descriptor]

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)

        guard let asset = fetchResult.firstObject else {
            return
        }

        let options = PHImageRequestOptions()
        let scale = UIScreen.main.scale
        let size = CGSize(width: (imageView?.frame.width ?? 0) * scale,
                          height: (imageView?.frame.height ?? 0) * scale)

        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { (image, info) in
            DispatchQueue.main.async {
                guard let image = image else { return }
                self.imageView?.image = image
                self.inference(with: image)
            }
        }
    }
}
