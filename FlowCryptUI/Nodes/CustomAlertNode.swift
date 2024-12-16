//
//  CustomAlertNode.swift
//  FlowCrypt
//
//  Created by Ioan Moldovan on 12/8/24
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

public final class CustomAlertNode: CoreAlertNode, ASTextNodeDelegate {

    private var overlayNode: ASDisplayNode!
    private var contentView: ASDisplayNode!
    private var separatorNode: ASDisplayNode!
    private var titleLabel: ASTextNode!
    private var messageLabel: ASTextNode!
    private var okayButton: ASButtonNode!

    private let title: String
    private let message: String?

    public var onOkay: (() -> Void)?

    // MARK: - Initialization

    public init(
        title: String,
        message: String? = nil
    ) {
        self.title = title
        self.message = message
        super.init()
        setupNodes()
    }

    private func createNodes() {
        overlayNode = createOverlayNode()
        contentView = createContentView()
        separatorNode = createSeparatorNode()
        titleLabel = createTextNode(text: title, isBold: true, fontSize: 17)
        messageLabel = createTextNode(text: message ?? "", isBold: false, fontSize: 13, identifier: "aid-custom-alert-message", detectLinks: true)
        messageLabel.delegate = self
        okayButton = createButtonNode(
            title: "ok".localized,
            color: .systemBlue,
            identifier: "aid-ok-button",
            action: #selector(okayButtonTapped)
        )
    }

    private func setupNodes() {
        createNodes()
        contentView.addSubnode(titleLabel)
        if message != nil {
            contentView.addSubnode(messageLabel)
        }
        contentView.addSubnode(separatorNode)
        contentView.addSubnode(okayButton)
        overlayNode.addSubnode(contentView)
        addSubnode(overlayNode)
    }

    // MARK: - Layout
    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let separatorInsetSpec = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0),
            child: separatorNode
        )

        let contentStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 10,
            justifyContent: .center,
            alignItems: .center,
            children: [titleLabel, messageLabel]
        )
        contentStack.style.flexGrow = 1.0

        let buttonStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [okayButton]
        )
        buttonStack.style.flexGrow = 1.0

        let verticalStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 10,
            justifyContent: .center,
            alignItems: .stretch,
            children: [contentStack, separatorInsetSpec, buttonStack]
        )

        let contentLayout = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 20, left: 20, bottom: 10, right: 20),
            child: verticalStack
        )

        contentView.layoutSpecBlock = { _, _ in
            return contentLayout
        }

        let contentViewInset = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10), child: contentView)

        let centerSpec = ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: [], child: contentViewInset)

        overlayNode.layoutSpecBlock = { _, _ in
            return centerSpec
        }
        return ASWrapperLayoutSpec(layoutElement: overlayNode)
    }

    @objc private func okayButtonTapped() {
        onOkay?()
    }

    public func textNode(_ textNode: ASTextNode, tappedLinkAttribute attribute: String, value: Any, at point: CGPoint, textRange: NSRange) {
        if let url = value as? URL {
            UIApplication.shared.open(url)
        }
    }
}
