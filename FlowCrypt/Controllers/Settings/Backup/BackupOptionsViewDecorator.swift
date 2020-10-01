//
//  BackupOptionsViewDecorator.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 27/09/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

protocol BackupOptionsViewDecoratorType {
    var sceneTitle: String { get }
}

struct BackupOptionsViewDecorator: BackupOptionsViewDecoratorType {
    let sceneTitle = "backup_option_screen_title".localized
    
    
}
