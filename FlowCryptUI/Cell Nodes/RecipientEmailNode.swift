//
//  RecipientEmailNode.swift
//  FlowCryptUIApplication
//
//  Created by Anton Kharchevskyi on 21/02/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import FlowCryptCommon

final class RecipientEmailNode: CellNode {
    enum Constants {
        static let titleInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        static let layoutInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
    }
    
    enum Tap {
        case image, text
    }

    struct Input {
        let recipient: RecipientEmailsCellNode.Input
        let width: CGFloat
    }

    let titleNode = ASTextNode2()
    let input: Input
    let displayNode = ASDisplayNode()
    let imageNode = ASImageNode()

    private var onTap: ((Tap) -> Void)?

    init(input: Input) {
        self.input = input
        super.init()
        titleNode.attributedText = "  ".attributed() + input.recipient.email + "  ".attributed()
        titleNode.backgroundColor = input.recipient.state.backgroundColor

        titleNode.cornerRadius = 8
        titleNode.clipsToBounds = true
        titleNode.borderWidth = 1
        titleNode.borderColor = input.recipient.state.borderColor.cgColor
        titleNode.textContainerInset = RecipientEmailNode.Constants.titleInsets

        displayNode.backgroundColor = .clear
        imageNode.image = input.recipient.state.stateImage
        imageNode.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch input.recipient.state {
            case .idle: self.animateImageRotation()
            case .error: self.animateImageScaling()
            case .keyFound, .keyNotFound, .selected: break
            }
        }
        imageNode.addTarget(self, action: #selector(handleTap(_:)), forControlEvents: .touchUpInside)
        titleNode.addTarget(self, action: #selector(handleTap(_:)), forControlEvents: .touchUpInside)
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
        animation.toValue =  Double.pi * 2.0
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
        animation.toValue =  1.0
        animation.duration = 0.5
        animation.repeatCount = 1
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        imageNode.layer.add(animation, forKey: "scale")
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        displayNode.style.preferredSize.width = input.width
        displayNode.style.preferredSize.height = 1
        let spec = ASStackLayoutSpec()
        spec.children = [displayNode, titleNode]
        spec.direction = .vertical
        spec.alignItems = .baselineFirst
        let elements: [ASLayoutElement]

        if imageNode.image == nil {
            elements = [spec]
        } else {
            elements = [imageNode, spec]
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
