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
//  CVPixelBufferExtension.swift
//  PoseEstimation-TFLiteSwift
//
//  Created by Doyoung Gwak on 2020/03/16.
//  Copyright © 2020 Doyoung Gwak. All rights reserved.
//

import Accelerate
import Foundation

extension CVPixelBuffer {
    var size: CGSize {
        return CGSize(width: CVPixelBufferGetWidth(self), height: CVPixelBufferGetHeight(self))
    }
    
    /// Returns a new `CVPixelBuffer` created by taking the self area and resizing it to the
    /// specified target size. Aspect ratios of source image and destination image are expected to be
    /// same.
    ///
    /// - Parameters:
    ///   - from: Source area of image to be cropped and resized.
    ///   - to: Size to scale the image to(i.e. image size used while training the model).
    /// - Returns: The cropped and resized image of itself.
    func resize(from source: CGRect, to size: CGSize) -> CVPixelBuffer? {
        let inputImageRowBytes = CVPixelBufferGetBytesPerRow(self)
        let imageChannels = 4
        
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0)) }
        
        // Finds the address of the upper leftmost pixel of the source area.
        guard
            let inputBaseAddress = CVPixelBufferGetBaseAddress(self)?.advanced(
                by: Int(source.minY) * inputImageRowBytes + Int(source.minX) * imageChannels)
            else {
                return nil
        }
        
        // Crops given area as vImage Buffer.
        var croppedImage = vImage_Buffer(
            data: inputBaseAddress, height: UInt(source.height), width: UInt(source.width),
            rowBytes: inputImageRowBytes)
        
        let resultRowBytes = Int(size.width) * imageChannels
        guard let resultAddress = malloc(Int(size.height) * resultRowBytes) else {
            return nil
        }
        
        // Allocates a vacant vImage buffer for resized image.
        var resizedImage = vImage_Buffer(
            data: resultAddress,
            height: UInt(size.height), width: UInt(size.width),
            rowBytes: resultRowBytes
        )
        
        // Performs the scale operation on cropped image and stores it in result image buffer.
        guard vImageScale_ARGB8888(&croppedImage, &resizedImage, nil, vImage_Flags(0)) == kvImageNoError
            else {
                return nil
        }
        
        let releaseCallBack: CVPixelBufferReleaseBytesCallback = { mutablePointer, pointer in
            if let pointer = pointer {
                free(UnsafeMutableRawPointer(mutating: pointer))
            }
        }
        
        var result: CVPixelBuffer?
        
        // Converts the thumbnail vImage buffer to CVPixelBuffer
        let conversionStatus = CVPixelBufferCreateWithBytes(
            nil,
            Int(size.width), Int(size.height),
            CVPixelBufferGetPixelFormatType(self),
            resultAddress,
            resultRowBytes,
            releaseCallBack,
            nil,
            nil,
            &result
        )
        
        guard conversionStatus == kCVReturnSuccess else {
            free(resultAddress)
            return nil
        }
        
        return result
    }
}
