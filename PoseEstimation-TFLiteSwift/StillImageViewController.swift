//
//  StillImageViewController.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/20.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import UIKit

class StillImageViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var overlayView: PoseKeypointsDrawingView?
    
    // MARK: - ML Property
    let poseEstimator: PoseEstimator = PoseNetPoseEstimator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup UI
        setUpUI()
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
        
        imageView?.image = pickedImage
        picker.dismiss(animated: true)
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
