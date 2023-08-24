//
//  AvatarCheckboxNode.swift
//  FlowCryptUI
//
//  Created by Ioan Moldovan on 8/15/23
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit

class AvatarCheckboxNode: ASDisplayNode {
    private lazy var avatarNode: ASImageNode = {
        var emailString = emailText
        // extract the text that comes after "To:" because in `Sent` folder, emailText becomes `To: xx`
        // https://github.com/FlowCrypt/flowcrypt-ios/pull/2320#discussion_r1294448818
        if let range = emailString.range(of: "To: ") {
            emailString = String(emailString[range.upperBound...])
        }
        return getAvatarImage(text: emailString)
    }()

    private lazy var checkboxNode: ASImageNode = {
        let node = ASImageNode()
        let configuration = UIImage.SymbolConfiguration(pointSize: 20)
        node.image = UIImage(systemName: "checkmark", withConfiguration: configuration)?.tinted(.white)
        node.contentMode = .center
        node.cornerRadius = .Avatar.width / 2
        node.backgroundColor = .main
        node.style.preferredSize = CGSize(width: .Avatar.width, height: .Avatar.height)
        return node
    }()

    var onSelectionChange: ((Bool) -> Void)?
    private var isSelected = false
    private let emailText: String

    public init(emailText: String) {
        self.emailText = emailText
        super.init()
        automaticallyManagesSubnodes = true
        Task {
            await setupTapGesture()
        }
    }

    @MainActor
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCheckBox))
        view.addGestureRecognizer(tapGesture)
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let childNode: ASLayoutElement = isSelected ? checkboxNode : avatarNode
        return ASInsetLayoutSpec(insets: .zero, child: childNode)
    }

    public func toggleNode(forceTrue: Bool = false) {
        if forceTrue {
            isSelected = true
        } else {
            isSelected.toggle()
        }
        DispatchQueue.main.async {
            UIView.transition(with: self.view, duration: 0.3, options: .transitionFlipFromLeft) {
                self.setNeedsLayout()
            }
        }
    }

    @objc private func toggleCheckBox() {
        toggleNode()
        onSelectionChange?(isSelected)
    }
}
