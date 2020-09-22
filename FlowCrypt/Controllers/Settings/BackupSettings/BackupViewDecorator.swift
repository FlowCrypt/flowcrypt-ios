//
//  BackupViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 22/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import Foundation

protocol BackupViewDecoratorType {
    var sceneTitle: String { get }
}

struct BackupViewDecorator: BackupViewDecoratorType {
    let sceneTitle: String = "backup_screen_title".localized
}
