//
//  TextCellNode.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit
import Foundation

final class TextCellNode: CellNode {
    private let spinner = SpinnerNode()
    private let text = ASTextNode()
    private let size: CGSize
    private let withSpinner: Bool

    init(title: String, withSpinner: Bool, size: CGSize) {
        self.withSpinner = withSpinner
        self.size = size
        super.init()
        addSubnode(text)
        text.attributedText = NSAttributedString.text(from: title, style: .medium(16), color: .lightGray)
        if withSpinner {
            addSubnode(spinner)
        }
    }

    override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
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
            UIActivityIndicatorView(style: .gray)
        }
        style.preferredSize = CGSize(width: 20.0, height: 20.0)
    }

    override func didLoad() {
        super.didLoad()
        activityIndicatorView.startAnimating()
    }
}
