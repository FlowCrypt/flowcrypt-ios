//
//  PhotosManager.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 22.09.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation
import UIKit
import Photos
import Combine
import PhotosUI

typealias PhotoPickerViewController = UIViewController & PHPickerViewControllerDelegate
typealias TakePhotoViewController = UIViewController & UIImagePickerControllerDelegate & UINavigationControllerDelegate

protocol PhotosManagerType {
    func takePhoto(
        from viewController: TakePhotoViewController
    ) -> Future<Void, Error>

    func selectPhoto(
        from viewController: PhotoPickerViewController
    ) -> Future<Void, Error>
}

enum PhotosManagerError: Error {
    case noAccessToCamera
    case cantFetchMovie
    case cantFetchImage
}

class PhotosManager: PhotosManagerType {

    func takePhoto(
        from viewController: TakePhotoViewController
    ) -> Future<Void, Error> {
        Future<Void, Error> { promise in
            DispatchQueue.main.async {
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = viewController
                imagePicker.sourceType = .camera
                switch status {
                case .authorized, .notDetermined:
                    viewController.present(imagePicker, animated: true, completion: nil)
                    promise(.success(()))
                default:
                    promise(.failure(PhotosManagerError.noAccessToCamera))
                }
            }
        }
    }

    func selectPhoto(
        from viewController: PhotoPickerViewController
    ) -> Future<Void, Error> {
        Future<Void, Error> { promise in
            DispatchQueue.main.async {
                var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
                config.selectionLimit = 1
                config.filter = PHPickerFilter.any(of: [.images, .videos])

                let pickerViewController = PHPickerViewController(configuration: config)
                pickerViewController.delegate = viewController
                viewController.present(pickerViewController, animated: true, completion: nil)
                promise(.success(()))
            }
        }
    }
}
