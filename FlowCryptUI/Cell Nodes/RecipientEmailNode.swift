//
//  RecipientEmailNode.swift
//  FlowCryptUIApplication
//
//  Created by Anton Kharchevskyi on 21/02/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import UIKit

final class RecipientEmailNode: CellNode {
    enum Constants {
        static let titleInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        static let layoutInsets = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
    }

    enum Tap {
        case image, text
    }

    struct Input {
        let recipient: RecipientEmailsCellNode.Input
        let width: CGFloat
    }

    let titleNode = ASTextNode()
    let input: Input
    let imageNode = ASImageNode()

    var onTap: ((Tap) -> Void)?

    init(input: Input, index: Int) {
        self.input = input
        super.init()

        if let stateAccessibilityIdentifier = input.recipient.state.accessibilityIdentifier {
            accessibilityIdentifier = "aid-\(input.recipient.type)-\(index)-\(stateAccessibilityIdentifier)"
        }

        titleNode.attributedText = "  ".attributed() + input.recipient.email + "  ".attributed()
        titleNode.backgroundColor = input.recipient.state.backgroundColor
        titleNode.accessibilityIdentifier = "aid-\(input.recipient.type)-\(index)-label"

        titleNode.cornerRadius = 8
        titleNode.clipsToBounds = true
        titleNode.borderWidth = 1
        titleNode.borderColor = input.recipient.state.borderColor.cgColor
        titleNode.textContainerInset = Self.Constants.titleInsets

        imageNode.image = input.recipient.state.stateImage
        imageNode.alpha = 0
        imageNode.accessibilityIdentifier = "aid-recipient-spinner"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch input.recipient.state {
            case .idle: self.animateImageRotation()
            case .error: self.animateImageScaling()
            case .keyFound, .keyExpired, .keyRevoked, .keyNotFound, .invalidEmail, .keyNotUsableForEncryption, .keyNotUsableForSigning:
                break
            }
        }
        imageNode.addTarget(self, action: #selector(handleTap), forControlEvents: .touchUpInside)
        titleNode.addTarget(self, action: #selector(handleTap), forControlEvents: .touchUpInside)
    }

    @objc private func handleTap(_ sender: ASDisplayNode) {
        switch sender {
        case imageNode: onTap?(Tap.image)
        case titleNode: onTap?(Tap.text)
        default: break
        }
    }

    func onTapAction(_ block: ((Tap) -> Void)?) -> Self {
        self.onTap = block
        return self
    }

    private func animateImageRotation() {
        guard input.recipient.state.stateImage != nil else { return }
        imageNode.alpha = 1
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue = Double.pi * 2.0
        animation.duration = 2
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        imageNode.layer.add(animation, forKey: "spin")
    }

    private func animateImageScaling() {
        guard imageNode.image != nil else { return }
        imageNode.alpha = 1
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 0.9
        animation.toValue = 1.0
        animation.duration = 0.5
        animation.repeatCount = 1
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        imageNode.layer.add(animation, forKey: "scale")
    }

    override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let elements: [ASLayoutElement]

        if imageNode.image == nil {
            elements = [titleNode]
        } else {
            elements = [imageNode, titleNode]
            imageNode.hitTestSlop = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -20)
        }

        return ASInsetLayoutSpec(
            insets: Constants.layoutInsets,
            child: ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 20,
                justifyContent: .start,
                alignItems: .center,
                children: elements
            )
        )
    }
}
