//
//  TextCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon
import UIKit

public final class TextCellNode: CellNode {
    public struct Input {
        let backgroundColor: UIColor
        let title: String
        let withSpinner: Bool
        let size: CGSize
        let insets: UIEdgeInsets
        let alignment: NSTextAlignment?

        public init(
            backgroundColor: UIColor,
            title: String,
            withSpinner: Bool,
            size: CGSize,
            insets: UIEdgeInsets = .zero,
            alignment: NSTextAlignment? = nil
        ) {
            self.backgroundColor = backgroundColor
            self.title = title
            self.withSpinner = withSpinner
            self.size = size
            self.insets = insets
            self.alignment = alignment
        }
    }

    private let spinner = SpinnerNode()
    private let textNode = ASTextNode2()
    private let size: CGSize
    private let insets: UIEdgeInsets
    private let withSpinner: Bool

    public init(input: Input) {
        withSpinner = input.withSpinner
        size = input.size
        insets = input.insets
        super.init()
        addSubnode(textNode)
        textNode.attributedText = NSAttributedString.text(from: input.title, style: .medium(16), color: .lightGray, alignment: input.alignment)
        if input.withSpinner {
            addSubnode(spinner)
        }
        backgroundColor = input.backgroundColor
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 16,
            justifyContent: .center,
            alignItems: .center,
            children: withSpinner
                ? [textNode, spinner]
                : [textNode]
        )
        return ASInsetLayoutSpec(insets: insets, child: spec)
    }
}

final class SpinnerNode: ASDisplayNode {
    var activityIndicatorView: UIActivityIndicatorView {
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
