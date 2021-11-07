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

typealias PhotoViewController = UIViewController
& UIImagePickerControllerDelegate
& UINavigationControllerDelegate
& PHPickerViewControllerDelegate

protocol PhotosManagerType {
    func selectPhoto(
        source: UIImagePickerController.SourceType,
        from viewController: PhotoViewController
    ) -> Future<Void, Error>
}

enum PhotosManagerError: Error {
    case noAccessToLibrary
}

class PhotosManager: PhotosManagerType {

    func selectPhoto(
        source: UIImagePickerController.SourceType,
        from viewController: PhotoViewController
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
