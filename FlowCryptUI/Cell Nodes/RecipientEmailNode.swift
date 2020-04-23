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
    struct Input {
        let recipient: RecipientEmailsCellNode.Input
        let width: CGFloat
    }

    let titleNode = ASTextNode()
    let input: Input
    let displayNode = ASDisplayNode()
    let imageNode = ASImageNode()

    init(input: Input) {
        self.input = input
        super.init()
        titleNode.attributedText = "  ".attributed() + input.recipient.email + "  ".attributed()
        titleNode.backgroundColor = input.recipient.state.backgroundColor

        titleNode.cornerRadius = 8
        titleNode.clipsToBounds = true
        titleNode.borderWidth = 1
        titleNode.borderColor = input.recipient.state.borderColor.cgColor

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
        animation.fromValue = 0.5
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


        let elements: [ASLayoutElement] = imageNode.image == nil
            ? [spec]
            : [imageNode, spec]

        return ASInsetLayoutSpec(
            insets: .zero,
            child: ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 8,
                justifyContent: .start,
                alignItems: .center,
                children: elements
            )
        )
    }
}
