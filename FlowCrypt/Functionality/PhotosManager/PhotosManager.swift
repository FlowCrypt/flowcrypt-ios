//
//  PhotosManager.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 22.09.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
import UIKit
import Photos
import Combine

protocol PhotosManagerType {
    func selectPhoto(source: UIImagePickerController.SourceType, from viewController: UIViewController & UIImagePickerControllerDelegate & UINavigationControllerDelegate) -> Future<Void, Error>
}

enum PhotosManagerError: Error {
    case noAccessToLibrary
}

class PhotosManager: PhotosManagerType {
    func selectPhoto(
        source: UIImagePickerController.SourceType,
        from viewController: UIViewController & UIImagePickerControllerDelegate & UINavigationControllerDelegate
    ) -> Future<Void, Error> {
        Future<Void, Error> { promise in
            DispatchQueue.main.async {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = viewController
                imagePicker.sourceType = source
                PHPhotoLibrary.requestAuthorization { status in
                    switch status {
                    case .authorized:
                        DispatchQueue.main.async {
                            viewController.present(imagePicker, animated: true, completion: nil)
                        }
                        promise(.success(()))
                    case .denied, .restricted, .notDetermined, .limited:
                        promise(.failure(PhotosManagerError.noAccessToLibrary))
                    @unknown default: fatalError()
                    }
                }
            }
        }
    }
}
