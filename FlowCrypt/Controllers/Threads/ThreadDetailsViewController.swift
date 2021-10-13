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
        let sender = threadMessage.message.sender ?? "message_unknown_sender".localized
        let date = DateFormatter().formatDate(threadMessage.message.date)
        let isMessageRead = threadMessage.message.isMessageRead

        let collapseImage = #imageLiteral(resourceName: "arrow_up").tinted(.white)
        let expandImage = #imageLiteral(resourceName: "arrow_down").tinted(.white)
        let image = threadMessage.isExpanded ? expandImage : collapseImage

        let style: NSAttributedString.Style = isMessageRead
            ? .regular(17)
            : .bold(17)

        let dateColor: UIColor = isMessageRead
            ? .lightGray
            : .main

        let textColor: UIColor = isMessageRead
            ? .lightGray
            : .mainTextUnreadColor

        self.init(
            title: NSAttributedString.text(from: sender, style: style, color: textColor),
            subtitle: NSAttributedString.text(from: date, style: style, color: dateColor),
            image: image,
            imageSize: CGSize(width: 16, height: 16),
            nodeInsets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            backgroundColor: .backgroundColor
        )
    }
}

final class ThreadMessage {
    let message: Message
    var isExpanded: Bool

    init(message: Message, isExpanded: Bool) {
        self.message = message
        self.isExpanded = isExpanded
    }
}

final class ThreadDetailsViewController: TableNodeViewController {
    private let threadSubject: String?
    private let messages: [ThreadMessage]

    init(
        thread: MessageThread
    ) {
        self.threadSubject = thread.subject
        self.messages = thread.messages
            .sorted()
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
        title = threadSubject
    }

    private func handleTapOn(header: HeaderNode, at indexPath: IndexPath) {
        UIView.animate(
            withDuration: 0.3,
            animations: {
                header.imageNode.view.transform = CGAffineTransform(rotationAngle: .pi)
            },
            completion: { [weak self] _ in
                guard let self = self else { return }
                self.messages[indexPath.row].isExpanded = !self.messages[indexPath.row].isExpanded
                self.node.reloadRows(at: [indexPath], with: .fade)
            }
        )
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
                onTap: { [weak self] node in
                    self?.handleTapOn(header: node, at: indexPath)
                }
            )
        }
    }
}
