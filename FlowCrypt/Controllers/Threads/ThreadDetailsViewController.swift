//
//  ThreadDetailsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI

final class ThreadDetailsViewController: TableNodeViewController {
    private enum Parts: Int, CaseIterable {
        case thread, message
    }

    private let threadSubject: String?
    private let messages: [Input]

    init(
        thread: MessageThread
    ) {
        self.threadSubject = thread.subject
        self.messages = thread.messages
            .sorted()
            .map { Input(message: $0, isExpanded: false) }

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

    private func handleTapOn(threadNode: TextImageNode, at indexPath: IndexPath) {
        UIView.animate(
            withDuration: 0.3,
            animations: {
                threadNode.imageNode.view.transform = CGAffineTransform(rotationAngle: .pi)
            },
            completion: { [weak self] _ in
                guard let self = self else { return }
                self.messages[indexPath.section].isExpanded = !self.messages[indexPath.section].isExpanded
                self.node.reloadData()
            }
        )
    }
}

extension ThreadDetailsViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        messages.count
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return 2
        messages[section].isExpanded
            ? Parts.allCases.count
            : [Parts.message].count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Parts(rawValue: indexPath.row) else {
                return ASCellNode()
            }

            switch part {
            case .thread:
                return TextImageNode(
                    input: .init(threadMessage: self.messages[indexPath.row]),
                    onTap: { [weak self] node in
                        self?.handleTapOn(threadNode: node, at: indexPath)
                    }
                )
            case .message:
                let node = ASCellNode()
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard let node = tableNode.nodeForRow(at: indexPath) as? TextImageNode  else {
            return
        }

        handleTapOn(threadNode: node, at: indexPath)
    }
}
