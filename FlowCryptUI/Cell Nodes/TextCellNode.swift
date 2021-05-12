//
//  TextCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptCommon

public final class TextCellNode: CellNode {
    public struct Input {
        let backgroundColor: UIColor
        let title: String
        let withSpinner: Bool
        let size: CGSize

        public init(
            backgroundColor: UIColor,
            title: String,
            withSpinner: Bool,
            size: CGSize
        ) {
            self.backgroundColor = backgroundColor
            self.title = title
            self.withSpinner = withSpinner
            self.size = size
        }
    }

    private let spinner = SpinnerNode()
    private let text = ASTextNode2()
    private let size: CGSize
    private let withSpinner: Bool

    public init(input: Input) {
        withSpinner = input.withSpinner
        size = input.size
        super.init()
        addSubnode(text)
        text.attributedText = NSAttributedString.text(from: input.title, style: .medium(16), color: .lightGray)
        if input.withSpinner {
            addSubnode(spinner)
        }
        backgroundColor = input.backgroundColor
    }

    public override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 16,
            justifyContent: .center,
            alignItems: .center,
            children: withSpinner ? [text, spinner] : [text]
        )
        spec.style.preferredSize = size
        return spec
    }
}

final class SpinnerNode: ASDisplayNode {
    var activityIndicatorView: UIActivityIndicatorView {
        return view as! UIActivityIndicatorView
    }

    override init() {
        super.init()
        setViewBlock {
            switch UITraitCollection.current.userInterfaceStyle {
            case .dark: return UIActivityIndicatorView(style: .white)
            default: return UIActivityIndicatorView(style: .gray)
            }
        }
        style.preferredSize = CGSize(width: 20.0, height: 20.0)
    }

    override func didLoad() {
        super.didLoad()
        activityIndicatorView.startAnimating()
    }
}
