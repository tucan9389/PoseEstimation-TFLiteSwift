//
//  StillImageViewController.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/20.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import UIKit

class StillImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            imageView.image = nil
            picker.dismiss(animated: true)
            return
        }
        
        imageView.image = pickedImage
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension StillImageViewController: UINavigationControllerDelegate { }
