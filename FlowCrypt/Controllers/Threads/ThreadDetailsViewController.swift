//
//  ThreadDetailsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//
    
import AsyncDisplayKit
import FlowCryptUI

extension HeaderNode.Input {
    init(threadMessage: ThreadMessage) {
        let sender = "element.title"
        let date = "element.dateString"
        let msg = "element.subtitle"
        let isMessageRead = false

        let style: NSAttributedString.Style = isMessageRead
            ? .regular(17)
            : .bold(17)

        let dateColor: UIColor = isMessageRead
            ? .lightGray
            : .main

        let textColor: UIColor = isMessageRead
            ? .lightGray
            : .mainTextUnreadColor

//        self.init(
//            emailText: NSAttributedString.text(from: email, style: style, color: textColor),
//            dateText: NSAttributedString.text(from: date, style: style, color: dateColor),
//            messageText: NSAttributedString.text(from: msg, style: style, color: textColor)
//        )

        let collapseImage = #imageLiteral(resourceName: "arrow_up").tinted(.white)
        let expandImage = #imageLiteral(resourceName: "arrow_down").tinted(.white)

        self.init(
            title: NSAttributedString.text(from: sender, style: style, color: textColor),
            subtitle: NSAttributedString.text(from: date, style: style, color: dateColor),
            image: expandImage,
            imageSize: CGSize(width: 16, height: 16),
            nodeInsets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            backgroundColor: .backgroundColor
        )
    }
}

class ThreadMessage {
    let message: Message
    var isExpanded: Bool

    init(message: Message, isExpanded: Bool) {
        self.message = message
        self.isExpanded = isExpanded
    }
}

final class ThreadDetailsViewController: TableNodeViewController {
    // TODO: - ANTON - remove if not needed
    private let thread: MessageThread
    private let messages: [ThreadMessage]

    init(
        thread: MessageThread
    ) {
        self.thread = thread
        self.messages = thread.messages
            .map { ThreadMessage(message: $0, isExpanded: false) }

        super.init(node: TableNode())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        node.delegate = self
        node.dataSource = self
        title = thread.subject
    }
}

extension ThreadDetailsViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self else { return ASCellNode() }

            return HeaderNode(
                input: .init(threadMessage: self.messages[indexPath.row]),
                onTap: {
                    print("tap")
                }
            )
        }
    }
}
