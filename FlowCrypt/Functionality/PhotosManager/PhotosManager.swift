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
import PhotosUI

typealias PhotoPickerViewController = UIViewController & PHPickerViewControllerDelegate
typealias TakePhotoViewController = UIViewController & UIImagePickerControllerDelegate & UINavigationControllerDelegate

@MainActor
protocol PhotosManagerType {
    func takePhoto(from viewController: TakePhotoViewController) async throws
    func selectPhoto(from viewController: PhotoPickerViewController) async
}

enum PhotosManagerError: Error {
    case noAccessToCamera
}

final class PhotosManager {
}

extension PhotosManager: PhotosManagerType {
    func takePhoto(from viewController: TakePhotoViewController) async throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized, .notDetermined:
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = viewController
            imagePicker.sourceType = .camera
            viewController.present(imagePicker, animated: true, completion: nil)
        default:
            throw PhotosManagerError.noAccessToCamera
        }
    }

    func selectPhoto(from viewController: PhotoPickerViewController) async {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.selectionLimit = 1
        config.filter = PHPickerFilter.any(of: [.images, .videos])

        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = viewController
        viewController.present(pickerViewController, animated: true, completion: nil)
    }
}
