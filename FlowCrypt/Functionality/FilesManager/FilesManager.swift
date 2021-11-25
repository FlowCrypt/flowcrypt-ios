//
//  FilesManager.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 16.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Combine
import UIKit

protocol FileType {
    var name: String { get }
    var size: Int { get }
    var data: Data { get }
}

protocol FilesManagerPresenter {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
}

protocol FilesManagerType {
    func save(file: FileType) async throws -> URL

    @discardableResult
    func selectFromFilesApp(from viewController: FilesManagerPresenter & UIDocumentPickerDelegate) -> Future<Void, Error>
}

class FilesManager: FilesManagerType {

    private let documentsDirectoryURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()

    func save(file: FileType) async throws -> URL {
        let url = self.documentsDirectoryURL.appendingPathComponent(file.name)
        try file.data.write(to: url)
        return url
    }

    @discardableResult
    func selectFromFilesApp(
        from viewController: FilesManagerPresenter & UIDocumentPickerDelegate
    ) -> Future<Void, Error> {
        Future<Void, Error> { future in
            DispatchQueue.main.async {
                let documentController = UIDocumentPickerViewController(
                    documentTypes: ["public.data"], in: .import
                )
                documentController.delegate = viewController
                viewController.present(documentController, animated: true, completion: nil)
                future(.success(()))
            }
        }
    }
}
