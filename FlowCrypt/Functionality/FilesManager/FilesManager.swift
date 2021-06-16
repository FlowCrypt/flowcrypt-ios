//
//  FilesManager.swift
//  FlowCrypt
//
//  Created by Yevhen Kyivskyi on 16.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Promises

protocol FileType {
    var name: String { get }
    var size: Int { get }
    var data: Data { get }
}

protocol FilesManagerType {
    func download(file: FileType) -> Promise<Void>
}

class FilesManager: FilesManagerType {

    private let documentsDirectoryURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()

    private let queue: DispatchQueue = DispatchQueue.global(qos: .background)

    func download(file: FileType) -> Promise<Void> {
        Promise<Void> { [weak self] resolve, reject in
            guard let self = self else {
                throw AppErr.nilSelf
            }

            let url = self.documentsDirectoryURL.appendingPathComponent(file.name)
            self.queue.async {

                do {
                    try file.data.write(to: url)
                    resolve(())
                } catch {
                    reject(error)
                }
            }
        }
    }
}
