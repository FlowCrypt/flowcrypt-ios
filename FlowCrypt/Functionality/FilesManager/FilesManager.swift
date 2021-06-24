//
//  FilesManager.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 16.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Promises
import UIKit

protocol FileType {
    var name: String { get }
    var size: Int { get }
    var data: Data { get }
}

protocol FilesManagerType {
    func save(file: FileType) -> Promise<URL>
    func saveToFilesApp(file: FileType, from viewController: UIViewController & UIDocumentPickerDelegate) -> Promise<Void>
}

class FilesManager: FilesManagerType {

    private let documentsDirectoryURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()

    private let queue: DispatchQueue = DispatchQueue.global(qos: .background)

    func save(file: FileType) -> Promise<URL> {
        Promise<URL> { [weak self] resolve, reject in
            guard let self = self else {
                throw AppErr.nilSelf
            }

            let url = self.documentsDirectoryURL.appendingPathComponent(file.name)
            self.queue.async {

                do {
                    try file.data.write(to: url)
                    resolve(url)
                } catch {
                    reject(error)
                }
            }
        }
    }

    func saveToFilesApp(
        file: FileType,
        from viewController: UIViewController & UIDocumentPickerDelegate
    ) -> Promise<Void> {
        Promise<Void> { [weak self] resolve, _ in
            guard let self = self else {
                throw AppErr.nilSelf
            }
            let url = try? awaitPromise(self.save(file: file))
            DispatchQueue.main.async {
                let documentController = UIDocumentPickerViewController(url: url!, in: .exportToService)
                documentController.delegate = viewController
                viewController.present(documentController, animated: true)
                resolve(())
            }
        }
    }
}
