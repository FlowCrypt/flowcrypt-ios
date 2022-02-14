//
//  TestElement.swift
//  FlowCryptUIApplication
//
//  Created by Anton Kharchevskyi on 19/02/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon

final public class RecipientEmailsCellNode: CellNode {
    public typealias RecipientTap = (RecipientEmailTapAction) -> Void

    public enum RecipientEmailTapAction {
        case select(IndexPath)
        case imageTap(IndexPath)
    }

    private enum Constants {
        static let sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        static let minimumLineSpacing: CGFloat = 4
    }

    private var onAction: RecipientTap?

    private var toggleButtonAction: (() -> Void)?
    private lazy var toggleButtonNode: ASButtonNode = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        let image = UIImage(systemName: "chevron.down", withConfiguration: configuration)
        let button = ASButtonNode()
        button.setImage(image, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        button.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.secondaryLabel)
        button.addTarget(self, action: #selector(onToggleButtonTap), forControlEvents: .touchUpInside)
        return button
    }()

    var isToggleButtonRotated = false {
        didSet {
            updateButton()
        }
    }

    private lazy var layout: LeftAlignedCollectionViewFlowLayout = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = Constants.minimumLineSpacing
        layout.sectionInset = Constants.sectionInset
        return layout
    }()

    private lazy var toggleButton: ASButtonNode = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 16, weight: .light)
        let image = UIImage(systemName: "chevron.down", withConfiguration: configuration)
        let button = ASButtonNode()
        button.setImage(image, for: .normal)
        button.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.secondaryLabel)
        return button
    }()

    public lazy var collectionNode: ASCollectionNode = {
        let node = ASCollectionNode(collectionViewLayout: layout)
        node.accessibilityIdentifier = "aid-recipients-list"
        node.backgroundColor = .clear
        return node
    }()
    private var collectionLayoutHeight: CGFloat
    private var recipients: [Input] = []

    public init(recipients: [Input],
                height: CGFloat,
                isToggleButtonRotated: Bool,
                toggleButtonAction: (() -> Void)?) {
        self.recipients = recipients
        self.collectionLayoutHeight = height
        super.init()
        collectionNode.dataSource = self
        collectionNode.delegate = self

        DispatchQueue.main.async {
            self.collectionNode.view.contentInsetAdjustmentBehavior = .never
        }

        automaticallyManagesSubnodes = true

        self.isToggleButtonRotated = isToggleButtonRotated
        self.toggleButtonAction = toggleButtonAction
    }

    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        collectionNode.style.preferredSize.height = recipients.isEmpty ? 0 : collectionLayoutHeight

        if toggleButtonAction != nil {
            let buttonSize = CGSize(width: 40, height: 50)

            toggleButtonNode.style.preferredSize = buttonSize

            collectionNode.style.preferredSize.width = constrainedSize.max.width - buttonSize.width - 4

            let stack = ASStackLayoutSpec.horizontal()
            stack.children = [collectionNode, toggleButtonNode]

            DispatchQueue.main.async {
                self.toggleButtonNode.view.transform = CGAffineTransform(rotationAngle: self.isToggleButtonRotated ? .pi : 0)
            }

            return ASInsetLayoutSpec(insets: .zero, child: stack)
        } else {
            collectionNode.style.preferredSize.width = constrainedSize.max.width
            return ASInsetLayoutSpec(insets: .zero, child: collectionNode)
        }
    }

    private func updateButton() {
        UIView.animate(withDuration: 0.3) {
            self.toggleButtonNode.view.transform = CGAffineTransform(rotationAngle: self.isToggleButtonRotated ? .pi : 0)
        }
    }

    @objc private func onToggleButtonTap() {
        isToggleButtonRotated.toggle()
        toggleButtonAction?()
    }
}

extension RecipientEmailsCellNode {
    public func onItemSelect(_ action: RecipientTap?) -> Self {
        self.onAction = action
        return self
    }

    public func onLayoutHeightChanged(_ completion: @escaping (CGFloat) -> Void) -> Self {
        self.layout.onHeightChanged = completion
        return self
    }
}

extension RecipientEmailsCellNode: ASCollectionDelegate, ASCollectionDataSource {
    public func collectionNode(_: ASCollectionNode, numberOfItemsInSection _: Int) -> Int {
        recipients.count
    }

    public func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let width = collectionNode.style.preferredSize.width
        return { [weak self] in
            guard let recipient = self?.recipients[indexPath.row] else { assertionFailure(); return ASCellNode() }

            return RecipientEmailNode(
                input: RecipientEmailNode.Input(recipient: recipient, width: width),
                index: indexPath.row
            )
                .onTapAction { [weak self] action in
                    switch action {
                    case .image: self?.onAction?(.imageTap(indexPath))
                    case .text: self?.onAction?(.select(indexPath))
                    }
                }
        }
    }
}
