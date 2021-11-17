//
//  AttachmentNode.swift
//  FlowCryptUI
//

import AsyncDisplayKit

public final class AttachmentNode: CellNode {
    public struct Input {
        let name: NSAttributedString
        let size: NSAttributedString

        public init(name: NSAttributedString, size: NSAttributedString) {
            self.name = name
            self.size = size
        }
    }

    private let titleNode = ASTextNode()
    private let subtitleNode = ASTextNode2()
    private let imageNode = ASImageNode()
    private let borderNode = ASDisplayNode()
    private let deleteButtonNode = ASButtonNode()

    private var onDeleteTap: (() -> Void)?

    public init(
        input: Input,
        onDeleteTap: (() -> Void)? = nil
    ) {
        self.onDeleteTap = onDeleteTap
        super.init()
        automaticallyManagesSubnodes = true
        borderNode.borderWidth = 1.0
        borderNode.cornerRadius = 8.0
        borderNode.borderColor = UIColor.lightGray.cgColor
        borderNode.isUserInteractionEnabled = false

        imageNode.tintColor = .gray
        deleteButtonNode.setImage(UIImage(named: "cancel")?.tinted(.gray), for: .normal)
        imageNode.image = UIImage(named: "paperclip")?.tinted(.gray)
        titleNode.attributedText = input.name
        subtitleNode.attributedText = input.size
        
        deleteButtonNode.addTarget(self, action: #selector(onDeleteButtonTap), forControlEvents: .touchUpInside)
        deleteButtonNode.isHidden = onDeleteTap == nil
    }
    
    @objc private func onDeleteButtonTap() {
        onDeleteTap?()
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.spacing = 3
        verticalStack.style.flexShrink = 1.0
        verticalStack.style.flexGrow = 1.0

        verticalStack.children = [titleNode, subtitleNode]

        let finalSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 10,
            justifyContent: .start,
            alignItems: .center,
            children: [imageNode, verticalStack, deleteButtonNode]
        )

        let borderInset = UIEdgeInsets.side(8)

        let resultSpec = ASInsetLayoutSpec(
            insets: UIEdgeInsets(
                top: 8 + borderInset.top,
                left: 16 + borderInset.left,
                bottom: 8 + borderInset.bottom,
                right: 17 + borderInset.right
            ),
            child: finalSpec
        )

        return ASOverlayLayoutSpec(
            child: resultSpec,
            overlay: ASInsetLayoutSpec(
                insets: borderInset,
                child: borderNode
            )
        )
    }
}
