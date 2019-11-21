//
//  SetupViewController+Setup.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 14.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension SetupViewController {
   enum Parts: Int, CaseIterable {
       case title, description, passPhrase, divider, action, optionalAction
   }

   enum SetupAction { // importing key is in different VC: ImportKeyViewController
       case recoverKey, createKey
   }

   enum SetupButtonType {
       case loadAccount, createKey
   }
}
