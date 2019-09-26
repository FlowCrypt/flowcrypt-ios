//
//  TailLoadingCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 26.09.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

final class TailLoadingCellNode: ASCellNode {
    private let spinner = SpinnerNode()
    private let text = ASTextNode()

    override init() {
        super.init()

        addSubnode(text)
        text.attributedText = NSAttributedString.text(from: "Loading...", style: .regular(12), color: .lightGray)
        addSubnode(spinner)
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 16,
            justifyContent: .center,
            alignItems: .center,
            children: [ text, spinner ])
    }
}

final class SpinnerNode: ASDisplayNode {
    var activityIndicatorView: UIActivityIndicatorView {
        return view as! UIActivityIndicatorView
    }

    override init() {
        super.init()
        setViewBlock {
            UIActivityIndicatorView(style: .gray)
        }

        self.style.preferredSize = CGSize(width: 20.0, height: 20.0)
    }

    override func didLoad() {
        super.didLoad()

        activityIndicatorView.startAnimating()
    }
}
