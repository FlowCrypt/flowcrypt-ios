//
//  TextNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 16/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class TextNode: ASTextNode {
    override func canBecomeFirstResponder() -> Bool {
        true
    }
//
//    override func resignFirstResponder() -> Bool {
//        let menuController = UIMenuController.shared
//        if menuController.isMenuVisible {
//            menuController.setMenuVisible(false, animated: true)
//        }
//        return true
//    }
//
    override func canPerformAction(_ action: Selector, withSender sender: Any) -> Bool {
        print("^^ \(action)")
        return true
    }


}

//extension TextNode: UIResponderStandardEditActions {
//    func copy(_ sender: Any?) {
//
//    }
//}
