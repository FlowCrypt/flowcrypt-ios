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

typealias PhotoViewController = UIViewController
& UIImagePickerControllerDelegate
& UINavigationControllerDelegate

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

    enum MediaType {
        static let image = "public.image"
    }

    func selectPhoto(
        source: UIImagePickerController.SourceType,
        from viewController: UIViewController & UIImagePickerControllerDelegate & UINavigationControllerDelegate
    ) -> Future<Void, Error> {
        Future<Void, Error> { promise in
            DispatchQueue.main.async {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = viewController
                imagePicker.sourceType = source
                imagePicker.mediaTypes = [MediaType.image]
                viewController.present(imagePicker, animated: true, completion: nil)
                promise(.success(()))
            }
        }
    }
}
