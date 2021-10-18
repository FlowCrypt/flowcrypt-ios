//
//  ThreadDetailsViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12.10.2021
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import AsyncDisplayKit
import FlowCryptUI
import Promises
import FlowCryptCommon
import Foundation
import UIKit

final class ThreadDetailsViewController: TableNodeViewController {
    private lazy var logger = Logger.nested(Self.self)

    private enum Parts: Int, CaseIterable {
        case thread, message
    }

    private let messageService: MessageService
    private let thread: MessageThread
    private let messages: [ThreadDetailsViewController.Input]

    let trashFolderProvider: TrashFolderProviderType
    var currentFolderPath: String {
        thread.path
    }

    init(
        messageService: MessageService = MessageService(),
        trashFolderProvider: TrashFolderProviderType = TrashFolderProvider(),
        thread: MessageThread
    ) {
        self.messageService = messageService
        self.trashFolderProvider = trashFolderProvider
        self.thread = thread
        self.messages = thread.messages
            .sorted(by: { $0 > $1 })
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
        title = thread.subject

        setupNavigationBar()
        expandThreadMessage()
    }
}

extension ThreadDetailsViewController {
    private func handleTap(at indexPath: IndexPath) {
        guard let threadNode = node.nodeForRow(at: indexPath) as? TextImageNode else {
            logger.logError("Fail to handle tap at \(indexPath)")
            return
        }
        UIView.animate(
            withDuration: 0.3,
            animations: {
                threadNode.imageNode.view.transform = CGAffineTransform(rotationAngle: .pi)
            },
            completion: { [weak self] _ in
                self?.fetchDecryptAndRenderMsg(at: indexPath)
            }
        )
    }

    private func expandThreadMessage() {
        let indexOfSectionToExpand = thread.messages.firstIndex(where: { $0.isMessageRead == false }) ?? messages.count - 1
        let indexPath = IndexPath(row: 0, section: indexOfSectionToExpand)
        handleTap(at: indexPath)
    }
}

extension ThreadDetailsViewController {
    private func fetchDecryptAndRenderMsg(at indexPath: IndexPath) {
        let message = messages[indexPath.section].message
        logger.logInfo("Start loading message")

        showSpinner("loading_title".localized, isUserInteractionEnabled: true)

        Promise<ProcessedMessage> { [weak self] (resolve, _) in
            guard let self = self else { return }
            let promise = self.messageService.getAndProcessMessage(
                with: message,
                folder: self.thread.path
            )
            let processedMessage = try awaitPromise(promise)
            resolve(processedMessage)
        }
        .then(on: .main) { [weak self] message in
            self?.handleReceived(message: message, at: indexPath)
        }
        .catch(on: .main) { [weak self] error in
            self?.handleError(error, at: indexPath)
        }
    }

    private func handleReceived(message processedMessage: ProcessedMessage, at indexPath: IndexPath) {
        hideSpinner()

        self.messages[indexPath.section].processedMessage = processedMessage
        self.messages[indexPath.section].isExpanded = !self.messages[indexPath.section].isExpanded

        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.node.reloadSections(IndexSet(integer: indexPath.section), with: .fade)
            },
            completion: { _ in
                self.node.scrollToRow(at: indexPath, at: .middle, animated: true)
            })
        // TODO: - ANTON
        // asyncMarkAsReadIfNotAlreadyMarked()
    }

    private func handleError(_ error: Error, at indexPath: IndexPath) {
        logger.logInfo("Error \(error)")
        hideSpinner()

        switch error as? MessageServiceError {
        case let .missedPassPhrase(rawMimeData):
            handleMissedPassPhrase(for: rawMimeData, at: indexPath)
        case let .wrongPassPhrase(rawMimeData, passPhrase):
            handleWrongPathPhrase(for: rawMimeData, with: passPhrase, at: indexPath)
        default:
            // TODO: - Ticket - Improve error handling for MessageViewController
            if let someError = error as NSError?, someError.code == Imap.Err.fetch.rawValue {
                // todo - the missing msg should be removed from the list in inbox view
                // reproduce: 1) load inbox 2) move msg to trash on another email client 3) open trashed message in inbox
                showToast("Message not found in folder: \(thread.path)")
            } else {
                // todo - this should be a retry / cancel alert
                showAlert(error: error, message: "message_failed_open".localized + "\n\n\(error)")
            }
            navigationController?.popViewController(animated: true)
        }
    }

    private func handleMissedPassPhrase(for rawMimeData: Data, at indexPath: IndexPath) {
        let alert = AlertsFactory.makePassPhraseAlert(
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                self?.validateMessage(rawMimeData: rawMimeData, with: passPhrase, at: indexPath)
            })

        present(alert, animated: true, completion: nil)
    }

    private func handleWrongPathPhrase(for rawMimeData: Data, with phrase: String, at indexPath: IndexPath) {
        let alert = AlertsFactory.makeWrongPassPhraseAlert(
            onCancel: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            },
            onCompletion: { [weak self] passPhrase in
                self?.validateMessage(rawMimeData: rawMimeData, with: passPhrase, at: indexPath)
            })
        present(alert, animated: true, completion: nil)
    }

    private func validateMessage(rawMimeData: Data, with passPhrase: String, at indexPath: IndexPath) {
        showSpinner("loading_title".localized, isUserInteractionEnabled: true)

        messageService.validateMessage(rawMimeData: rawMimeData, with: passPhrase)
            .then(on: .main) { [weak self] message in
                self?.handleReceived(message: message, at: indexPath)
            }
            .catch(on: .main) { [weak self] error in
                self?.handleError(error, at: indexPath)
            }
    }
}

// TODO: - ANTON
extension ThreadDetailsViewController: MessageActionsHandler {

    func handleTrashTap() {

    }

    func handleArchiveTap() {

    }

    func handleMarkUnreadTap() {

    }
}

extension ThreadDetailsViewController: ASTableDelegate, ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        messages.count
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
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
                        self?.handleTap(at: indexPath)
                    }
                )
            case .message:
                let processedMessage = self.messages[indexPath.section].processedMessage
                return MessageTextSubjectNode(processedMessage.attributedMessage)
            }
        }
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard let node = tableNode.nodeForRow(at: indexPath) as? TextImageNode  else {
            return
        }
        handleTap(at: indexPath)
    }
}

// TODO: - ANTON

/*
 For actions on the conversation (mark unread) the buttons will remain on the top bar like before.

 mark unread: acts on whichever message is currently expanded in the thread
 delete: acts on whole thread (there should be api for that?)
 archive: acts on whole thread
 move to inbox: acts on whole thread

 */
