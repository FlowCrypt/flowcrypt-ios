//
//  TextCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import UIKit

public final class TextCellNode: CellNode {
    public struct Input {
        let backgroundColor: UIColor
        let title: String
        let withSpinner: Bool
        let size: CGSize
        let insets: UIEdgeInsets
        let textAlignment: NSTextAlignment?
        let itemsAlignment: ASStackLayoutAlignItems

        public init(
            backgroundColor: UIColor,
            title: String,
            withSpinner: Bool,
            size: CGSize,
            insets: UIEdgeInsets = .zero,
            textAlignment: NSTextAlignment? = nil,
            itemsAlignment: ASStackLayoutAlignItems = .center
        ) {
            self.backgroundColor = backgroundColor
            self.title = title
            self.withSpinner = withSpinner
            self.size = size
            self.insets = insets
            self.textAlignment = textAlignment
            self.itemsAlignment = itemsAlignment
        }
    }

    private let spinner = SpinnerNode()
    private let textNode = ASTextNode2()
    private let size: CGSize
    private let insets: UIEdgeInsets
    private let withSpinner: Bool
    private let itemsAlignment: ASStackLayoutAlignItems

    public init(input: Input) {
        withSpinner = input.withSpinner
        size = input.size
        insets = input.insets
        itemsAlignment = input.itemsAlignment
        super.init()
        addSubnode(textNode)
        textNode.attributedText = NSAttributedString.text(
            from: input.title,
            style: .medium(16),
            color: .lightGray,
            alignment: input.textAlignment
        )
        if input.withSpinner {
            addSubnode(spinner)
        }
        backgroundColor = input.backgroundColor
    }

    override public func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 16,
            justifyContent: .center,
            alignItems: itemsAlignment,
            children: withSpinner
                ? [textNode, spinner]
                : [textNode]
        )
        return ASInsetLayoutSpec(insets: insets, child: spec)
    }
}

final class SpinnerNode: ASDisplayNode {
    var activityIndicatorView: UIActivityIndicatorView {
        // swiftlint:disable:next force_cast
        return view as! UIActivityIndicatorView
    }

    override init() {
        super.init()
        setViewBlock {
            UIActivityIndicatorView(style: .medium)
        }
        style.preferredSize = CGSize(width: 20.0, height: 20.0)
    }

    override func didLoad() {
        super.didLoad()
        activityIndicatorView.startAnimating()
    }
}
