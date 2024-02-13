//
//  InboxCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import LetterAvatarKit
import UIKit

public protocol InboxCellNodeDelegate: AnyObject {
    func inboxCellNodeDidToggleSelection(_ node: InboxCellNode, isSelected: Bool)
}

public final class InboxCellNode: CellNode {
    public struct Input {
        public let emailText: NSAttributedString
        public let countText: NSAttributedString?
        public let dateText: NSAttributedString
        public let messageText: NSAttributedString?
        public let accessibilityidentifier: String?
        public let badgeText: NSAttributedString?
        public let isEncrypted: Bool
        public let hasAttachment: Bool
        public let onlyHavePublicKey: Bool

        public init(
            emailText: NSAttributedString,
            countText: NSAttributedString?,
            dateText: NSAttributedString,
            messageText: NSAttributedString?,
            accessibilityidentifier: String?,
            badgeText: NSAttributedString?,
            isEncrypted: Bool,
            hasAttachment: Bool,
            onlyHavePublicKey: Bool
        ) {
            self.emailText = emailText
            self.countText = countText
            self.dateText = dateText
            self.messageText = messageText
            self.accessibilityidentifier = accessibilityidentifier
            self.badgeText = badgeText
            self.isEncrypted = isEncrypted
            self.hasAttachment = hasAttachment
            self.onlyHavePublicKey = onlyHavePublicKey
        }
    }

    private enum Constants {
        static let iconSize: CGFloat = 20
        static let topBottomVerticalSpacing: CGFloat = 5
    }

    private let input: Input
    // Use custom isCellSelected rather than default isSelected
    // Because we have different behavior than default
    public var isCellSelected = false {
        didSet {
            updateSelectionAppearance()
        }
    }

    private lazy var avatarCheckboxNode: AvatarCheckboxNode = {
        let node = AvatarCheckboxNode(emailText: input.emailText.string)
        node.accessibilityIdentifier = "aid-avatar-checkbox"
        node.style.preferredSize = CGSize(width: .Avatar.width, height: .Avatar.height)

        node.onSelectionChange = { [weak self] isSelected in
            self?.delegate?.inboxCellNodeDidToggleSelection(self!, isSelected: isSelected)
        }
        return node
    }()

    // Use selected background solution to avoid darkening when changing the cell's background color with opacity,
    // especially when the user scrolls the screen.
    private lazy var selectedBackgroundNode: ASDisplayNode = {
        let node = ASDisplayNode()
        node.backgroundColor = .main.withAlphaComponent(0.2) // Set your color with desired opacity
        node.isHidden = true // Initially hidden
        node.isUserInteractionEnabled = false
        return node
    }()

    private lazy var emailNode = {
        let node = ASTextNode2()
        node.attributedText = input.emailText
        node.maximumNumberOfLines = 1
        node.truncationMode = .byTruncatingTail
        node.style.flexShrink = 1.0
        return node
    }()

    private lazy var countNode: ASTextNode2? = {
        let node = input.countText.map {
            let node = ASTextNode2()
            node.attributedText = $0
            return node
        }
        return node
    }()

    private lazy var dateNode = {
        let node = ASTextNode2()
        node.attributedText = input.dateText
        node.maximumNumberOfLines = 1
        return node
    }()

    private lazy var separatorNode = {
        let node = ASDisplayNode()
        node.backgroundColor = .separator
        return node
    }()

    private lazy var encryptedIcon: ASImageNode = {
        let node = ASImageNode()
        node.image = UIImage(systemName: "lock.shield")?.tinted(.main)
        node.style.preferredSize.width = Constants.iconSize
        node.style.preferredSize.height = Constants.iconSize
        return node
    }()

    private lazy var publicKeyIcon: ASImageNode = {
        let node = ASImageNode()
        node.image = UIImage(systemName: "person.badge.key")?.tinted(.lightGray)
        node.style.preferredSize.width = Constants.iconSize
        node.style.preferredSize.height = Constants.iconSize
        return node
    }()

    private lazy var attachmentIcon: ASImageNode = {
        let node = ASImageNode()
        node.image = UIImage(systemName: "paperclip")?.tinted(.lightGray)
        node.style.preferredSize.width = Constants.iconSize
        node.style.preferredSize.height = Constants.iconSize
        return node
    }()

    private lazy var messageNode = {
        let node = ASTextNode2()
        node.maximumNumberOfLines = 1
        node.truncationMode = .byTruncatingTail
        node.attributedText = input.messageText
        node.style.flexShrink = 1.0
        return node
    }()

    private lazy var badgeNode = {
        let node = ASTextNode()
        node.textContainerInset = .init(top: 1, left: 6, bottom: 1, right: 6)
        node.attributedText = input.badgeText
        node.cornerRadius = 6
        node.clipsToBounds = true
        node.backgroundColor = .main
        return node
    }()

    public weak var delegate: InboxCellNodeDelegate?

    public init(input: Input) {
        self.input = input

        super.init()

        accessibilityIdentifier = input.accessibilityidentifier
    }

    private func updateSelectionAppearance() {
        selectedBackgroundNode.isHidden = !isCellSelected
    }

    public func toggleCheckBox(forceTrue: Bool = false) {
        avatarCheckboxNode.toggleNode(forceTrue: forceTrue)
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let emailElement = ASStackLayoutSpec.horizontal()
        emailElement.spacing = 5
        emailElement.children = countNode == nil ? [emailNode] : [emailNode, countNode!]

        // Create Name-Location Stack
        let nameLocationStack = ASStackLayoutSpec.vertical()
        nameLocationStack.spacing = Constants.topBottomVerticalSpacing
        nameLocationStack.style.flexShrink = 1.0
        nameLocationStack.style.flexGrow = 1.0

        let messageBadgeStack = ASStackLayoutSpec.horizontal()
        messageBadgeStack.children = [messageNode, badgeNode]
        messageBadgeStack.alignItems = .center
        messageBadgeStack.spacing = 6

        // Configure message and badge
        nameLocationStack.children = input.badgeText == nil
            ? [emailElement, messageNode]
            : [emailElement, messageBadgeStack]

        // Setup separator
        separatorNode.style.preferredSize.height = 0.5

        let iconsSpec = ASStackLayoutSpec.horizontal()
        iconsSpec.spacing = 3
        iconsSpec.children = [
            input.hasAttachment && !input.onlyHavePublicKey ? attachmentIcon : nil,
            input.onlyHavePublicKey ? publicKeyIcon : nil,
            input.isEncrypted ? encryptedIcon : nil
        ].compactMap { $0 }

        let headerRightSpec = ASStackLayoutSpec.vertical()
        headerRightSpec.spacing = Constants.topBottomVerticalSpacing
        headerRightSpec.alignItems = .end
        headerRightSpec.children = [dateNode, iconsSpec]

        // Create Header Stack
        let headerStackSpec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: [avatarCheckboxNode, nameLocationStack, headerRightSpec]
        )

        // Final Vertical Stack
        let finalSpec = ASStackLayoutSpec.vertical()
        finalSpec.spacing = 10
        finalSpec.children = [headerStackSpec, separatorNode]

        // Create Inset Layout
        let spec = ASInsetLayoutSpec(
            insets: .deviceSpecificTextInsets(top: 12, bottom: 0),
            child: finalSpec
        )

        return ASOverlayLayoutSpec(child: spec, overlay: selectedBackgroundNode)
    }
}
