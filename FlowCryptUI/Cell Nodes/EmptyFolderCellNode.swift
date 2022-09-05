//
//  EmptyFolderCellNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 6/27/22
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

/// Node for `empty trash view` and `empty spam view`
public final class EmptyFolderCellNode: CellNode {

    private let path: String
    private let emptyFolder: (() -> Void)?

    private lazy var textNode: ASTextNode2 = {
        let textNode = ASTextNode2()
        textNode.attributedText = "folder_empty_\(path.lowercased())_introduce".localized.attributed(color: .mainTextColor)
        textNode.maximumNumberOfLines = 5
        return textNode
    }()
    private lazy var trashImageNode: ASImageNode = {
        let imageNode = ASImageNode()
        imageNode.image = UIImage(systemName: "trash")?.tinted(.main)
        imageNode.style.preferredSize = CGSize(width: 25, height: 30)
        return imageNode
    }()
    private lazy var emptyButtonNode: ASButtonNode = {
        let buttonNode = ASButtonNode()
        let text = "folder_empty_\(path.lowercased())_button_text".localized
        buttonNode.setAttributedTitle(text.attributed(color: .main), for: .normal)
        buttonNode.addTarget(self, action: #selector(onEmptyButtonTap), forControlEvents: .touchUpInside)
        buttonNode.accessibilityIdentifier = "aid-empty-folder-button"
        return buttonNode
    }()

    public init(path: String, emptyFolder: (() -> Void)?) {
        self.path = path
        self.emptyFolder = emptyFolder
        super.init()
    }

    @objc private func onEmptyButtonTap() {
        emptyFolder?()
    }

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let stack = ASStackLayoutSpec.horizontal()
        textNode.style.maxWidth = ASDimensionMake(constrainedSize.max.width - 60)
        stack.children = [
            trashImageNode,
            ASStackLayoutSpec(
                direction: .vertical,
                spacing: 10,
                justifyContent: .center,
                alignItems: .start,
                children: [textNode, emptyButtonNode]
            )
        ]
        stack.spacing = 20
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
            child: stack
        )
    }
}
