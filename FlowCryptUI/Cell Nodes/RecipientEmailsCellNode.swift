//
//  RecipientEmailsCellNode.swift
//  FlowCryptUIApplication
//
//  Created by Anton Kharchevskyi on 19/02/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class RecipientEmailsCellNode: CellNode {
    public typealias RecipientTap = (RecipientEmailTapAction) -> Void

    public enum RecipientEmailTapAction {
        case select(IndexPath, CellNode)
        case imageTap(IndexPath)
    }

    private enum Constants {
        static let sectionInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        static let minimumLineSpacing: CGFloat = 4
    }

    private var onAction: RecipientTap?

    lazy var textNode: ASTextNode2 = {
        let textNode = ASTextNode2()
        let textTitle = "compose_recipient_\(type)".localized
        textNode.attributedText = textTitle.attributed(.regular(17), color: .lightGray, alignment: .left)
        textNode.isAccessibilityElement = true
        textNode.style.preferredSize.width = 42
        return textNode
    }()

    lazy var toggleButtonNode: ASButtonNode = {
        createToggleButton()
    }()

    var toggleButtonAction: (() -> Void)?

    var isToggleButtonRotated = false {
        didSet {
            updateToggleButton(animated: true)
        }
    }

    private lazy var layout: RecipientEmailCollectionViewFlowLayout = {
        let layout = RecipientEmailCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = Constants.minimumLineSpacing
        layout.sectionInset = Constants.sectionInset
        return layout
    }()

    public lazy var collectionNode: ASCollectionNode = {
        let node = ASCollectionNode(collectionViewLayout: layout)
        node.accessibilityIdentifier = "aid-recipients-list-\(type)"
        node.backgroundColor = .clear
        return node
    }()
    private var collectionLayoutHeight: CGFloat
    private var recipients: [Input] = []
    private let type: String
    public let recipientInput: RecipientEmailTextFieldNode

    public init(recipients: [Input],
                recipientInput: RecipientEmailTextFieldNode,
                type: String,
                height: CGFloat,
                isToggleButtonRotated: Bool,
                toggleButtonAction: (() -> Void)?) {
        self.recipients = recipients
        self.type = type
        self.collectionLayoutHeight = height
        self.recipientInput = recipientInput

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

    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let collectionNodeSize = CGSize(width: constrainedSize.max.width, height: collectionLayoutHeight)
        let buttonSize = CGSize(width: 40, height: 32)

        let insets = UIEdgeInsets.deviceSpecificTextInsets(top: 0, bottom: 0)

        let textNodeStack = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0), child: textNode)

        return createLayout(
            contentNode: collectionNode,
            textNodeStack: textNodeStack,
            contentSize: collectionNodeSize,
            insets: insets,
            buttonSize: buttonSize
        )
    }

    public func setRecipientsInput(input: [Input]) {
        self.recipients = input
    }

    @objc func onToggleButtonTap() {
        isToggleButtonRotated.toggle()
        toggleButtonAction?()
    }
}

public extension RecipientEmailsCellNode {
    func onItemSelect(_ action: RecipientTap?) -> Self {
        self.onAction = action
        return self
    }

    func onLayoutHeightChanged(_ completion: @escaping (CGFloat) -> Void) -> Self {
        self.layout.onHeightChanged = completion
        return self
    }
}

extension RecipientEmailsCellNode: ASCollectionDelegate, ASCollectionDataSource {
    public func collectionNode(_: ASCollectionNode, numberOfItemsInSection _: Int) -> Int {
        recipients.count + 1
    }

    public func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let width = collectionNode.style.preferredSize.width

        return { [weak self] in
            guard let self = self else {
                return ASCellNode()
            }
            if indexPath.row == self.recipients.count {
                return self.recipientInput
            }

            guard let recipient = self.recipients[safe: indexPath.row] else { assertionFailure(); return ASCellNode() }

            let cell = RecipientEmailNode(
                input: RecipientEmailNode.Input(recipient: recipient, width: width),
                index: indexPath.row
            )
            cell.onTap = { [weak self] action in
                switch action {
                case .image: self?.onAction?(.imageTap(indexPath))
                case .text: self?.onAction?(.select(indexPath, cell))
                }
            }
            return cell
        }
    }
}

extension RecipientEmailsCellNode {
    func createToggleButton() -> ASButtonNode {
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        let image = UIImage(systemName: "chevron.down", withConfiguration: configuration)
        let button = ASButtonNode()
        button.accessibilityIdentifier = "aid-recipients-toggle-button"
        button.setImage(image, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0)
        button.imageNode.imageModificationBlock = ASImageNodeTintColorModificationBlock(.secondaryLabel)
        button.addTarget(self, action: #selector(self.onToggleButtonTap), forControlEvents: .touchUpInside)
        return button
    }

    func updateToggleButton(animated: Bool) {
        func rotateButton(angle: CGFloat) {
            toggleButtonNode.view.transform = CGAffineTransform(rotationAngle: angle)
        }

        let angle = self.isToggleButtonRotated ? .pi : 0
        if animated {
            UIView.animate(withDuration: 0.3) {
                rotateButton(angle: angle)
            }
        } else {
            rotateButton(angle: angle)
        }
    }

    func createLayout(
        contentNode: ASDisplayNode,
        textNodeStack: ASInsetLayoutSpec,
        contentSize: CGSize,
        insets: UIEdgeInsets,
        buttonSize: CGSize
    ) -> ASInsetLayoutSpec {

        contentNode.style.preferredSize.height = contentSize.height
        contentNode.style.flexGrow = 1

        let stack = ASStackLayoutSpec.horizontal()
        stack.children = [textNodeStack, collectionNode]

        if toggleButtonAction != nil {
            toggleButtonNode.style.preferredSize = buttonSize

            DispatchQueue.main.async {
                self.updateToggleButton(animated: false)
            }

            stack.children?.append(toggleButtonNode)
        }

        return ASInsetLayoutSpec(insets: insets, child: stack)
    }
}
