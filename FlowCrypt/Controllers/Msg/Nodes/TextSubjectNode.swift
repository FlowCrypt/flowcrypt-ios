//
//  TextSubjectNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 06.11.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class TextSubjectNode: CellNode {
    private let textNode = TextNode()

    init(_ text: NSAttributedString?) {
        super.init()
        textNode.attributedText = text
        isUserInteractionEnabled = true
        self.textNode.isUserInteractionEnabled = true

        DispatchQueue.main.async {
            let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressGesture))
            self.textNode.view.addGestureRecognizer(gestureRecognizer)
        }
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        textNode.style.flexGrow = 1.0
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            child: textNode
        )
    }

    override func canBecomeFirstResponder() -> Bool {
        true
    }

    @objc func handleLongPressGesture(recognizer: UIGestureRecognizer) {
        guard recognizer.state == .recognized else { return }

        if let recognizerView = recognizer.view,
            let recognizerSuperView = recognizerView.superview,
            recognizerView.becomeFirstResponder()
        {
            print("^^ recognizerView.frame \(recognizerView.frame)")
            let menuController = UIMenuController.shared
            menuController.menuItems = [UIMenuItem(title: "Copy", action: #selector(c))]
            menuController.setTargetRect(recognizerView.frame, in: recognizerSuperView)
            menuController.setMenuVisible(true, animated:true)
        }
    }

    @objc func c() {

    }
}
